# Reproduction steps

Single-account design — you only need your own GitHub account. The
`pull_request_target` trigger fires the same way for same-repo branch PRs as
it does for fork PRs; the bug class is identical.

## Phase 0 — Prerequisites

1. GitHub account: **`goat63262`** (already pinned in the workflow `if:` guard).
2. Exfiltration receiver: **Burp Collaborator** URL
   `https://ma0vigny6ca3tyopssyy7r4ppgv7j07p.oastify.com/exfil` is already
   baked into `exploit-artifacts/Makefile.malicious`. Keep your Collaborator
   poll window open in Burp during the run.

## Phase 1 — Set up the demo repo

1. Create a new **public** repo on GitHub. Suggested name:
   `minikube-pwn-request-demo`. Do NOT initialise it with a README.
2. From this local directory:
   ```bash
   cd "/d/Bug bounty/kubernetes/poc-demo"
   git init
   git add Makefile .github README.md STEPS.md
   git commit -m "Initial benign repo with vulnerable workflow"
   git branch -M main
   git remote add origin https://github.com/goat63262/minikube-pwn-request-demo.git
   git push -u origin main
   ```
3. In the GitHub UI for the new repo, go to **Settings → Secrets and variables
   → Actions → New repository secret** and create the five secrets below.
   Use distinctive strings so they are obvious in the webhook.site receiver:

   | Name | Value (example — pick anything distinctive) |
   |---|---|
   | `DEMO_FAKE_CLIENT_ID` | `DEMO-CLIENT-ID-LEAKED-aa11bb22` |
   | `DEMO_FAKE_PASSWORD` | `DEMO-PASSWORD-LEAKED-cc33dd44` |
   | `DEMO_FAKE_SUBSCRIPTION` | `DEMO-SUBSCRIPTION-LEAKED-ee55ff66` |
   | `DEMO_FAKE_TENANT_ID` | `DEMO-TENANT-LEAKED-gg77hh88` |
   | `DEMO_FAKE_VM_PASSWORD` | `DEMO-VM-PASSWORD-LEAKED-ii99jj00` |

4. Create the `ok-to-extra-test` label in the repo:
   **Issues tab → Labels → New label → Name: `ok-to-extra-test`**. Any colour.

## Phase 2 — Open the "benign" PR

1. From the same local directory:
   ```bash
   git checkout -b attacker-pr
   # tiny benign change — just touch the README so there's a diff
   echo "" >> README.md
   git commit -am "Trivial README touch (benign change)"
   git push -u origin attacker-pr
   ```
2. In GitHub UI, open a pull request from `attacker-pr` → `main`. Title:
   `Benign change`. This represents the attacker's initial PR.
3. **Important**: at this stage the workflow does NOT run yet, because no label
   has been applied.

## Phase 3 — Maintainer applies `ok-to-extra-test`

1. In the PR UI, click the gear next to **Labels** on the right sidebar and
   apply `ok-to-extra-test`.
2. **Observe**: under the **Checks** tab, the workflow `Functional Extra
   (DEMO...)` starts running on the BENIGN commit. Verify by viewing the
   workflow run's first step (`Print SHA being executed`) — it logs the
   benign commit's message.
3. The workflow run completes (Makefile prints "BENIGN BUILD"). No exfil — the
   benign Makefile does nothing harmful. **This represents the legitimate
   intended behaviour.**

## Phase 4 — Attacker force-pushes the malicious Makefile

This is the TOCTOU.

1. `exploit-artifacts/Makefile.malicious` is already pre-baked with the
   Collaborator URL — no edits needed.
2. Stage the malicious Makefile into the PR branch tree at the path the workflow
   builds (`Makefile`):
   ```bash
   # still on branch attacker-pr
   cp exploit-artifacts/Makefile.malicious Makefile
   git add Makefile
   git commit -m "Refactor build step"   # benign-looking commit message
   git push --force-with-lease origin attacker-pr
   ```
3. **Observe**: the workflow does NOT re-fire on this push. `pull_request_target`
   does not trigger on `synchronize` for this workflow (only on `labeled`).
   So the maintainer has no reason yet to look at the PR again — the previous
   "ok-to-extra-test" run already succeeded on the benign code.

## Phase 5 — Any subsequent label triggers exploitation

This is the moment the maintainer is tricked. Triage labels are applied to PRs
all the time. Any of them re-fires the workflow.

1. In the PR UI, apply any other label. Either create a new one (e.g.
   `kind/cleanup`, `area/build`, `lifecycle/active`) or use a default one. The
   specific label does NOT matter — the workflow's guard only checks that
   `ok-to-extra-test` is **already present in `labels[]`**, which it still is.
2. **Observe**: the workflow `Functional Extra (DEMO...)` runs again. This
   time, view the run's `Print SHA being executed` step — it now logs the
   MALICIOUS commit's hash and message ("Refactor build step").
3. The `Build` step executes the malicious `Makefile`'s `e2e-windows-amd64.exe`
   rule. It curls webhook.site with all five `DEMO_FAKE_*` values plus the
   `GITHUB_TOKEN`.
4. Open your Burp Collaborator poll — a fresh HTTP POST to
   `/exfil` has arrived containing all the leaked dummy secrets in the
   form body. The `runner`, `repo`, `actor`, `ref`, `sha` fields confirm the
   request originated from the GitHub Actions runner.

## What this proves

| Claim | Evidence |
|---|---|
| `event.pull_request.head.sha` resolves to live head SHA at labeled-event time, not labeling-history SHA | The "Print SHA" step in Phase 5 shows the malicious commit hash, not the benign one |
| Cumulative-label guard fails to bind to the firing event | Workflow re-fires on a label *other than* `ok-to-extra-test` because `ok-to-extra-test` is still present in `labels[]` |
| Secrets injected via `env:` reach attacker code in the build step | webhook.site receives all five `DEMO_FAKE_*` markers + `GITHUB_TOKEN` |
| The exact same workflow structure exists in kubernetes/minikube | See `D:\Bug bounty\kubernetes\workflow-audit\minikube\.github\workflows\functional_extra.yml`, identical lines 11–46 |

## Tear-down

After you have the workflow run URLs + webhook.site screenshots needed for the
report, delete the demo repo:

```bash
# Or delete via UI: Settings → Danger Zone → Delete this repository
```

## Attach to the H1 report

In the H1 report body, link or attach:

1. Workflow run URL from Phase 3 (benign run on `ok-to-extra-test`)
2. Workflow run URL from Phase 5 (malicious run on other label)
3. Burp Collaborator screenshot showing the inbound HTTP POST request with
   leaked dummy secrets in body
4. The two commit SHAs (benign and malicious) — both visible in the PR's commits tab

Combined with the static-analysis report (`reports/minikube-functional-extra-pwn-request.md`),
this gives the triager an end-to-end runtime demonstration of the bug class
without ever touching the live `kubernetes/minikube` repo or maintainers.
