# minikube `functional_extra.yml` pwn-request — Mirror PoC

This is a **self-contained reproduction** of the pull_request_target TOCTOU bug
class affecting `kubernetes/minikube`'s `.github/workflows/functional_extra.yml`.

The vulnerable workflow YAML in this repo is a faithful structural mirror of the
real upstream file. All "secrets" referenced are dummy markers — no real Azure
credentials are involved. The webhook.site URL acts as the exfiltration sink in
place of an attacker server.

## What the bug is (one paragraph)

The upstream workflow triggers on `pull_request_target: types: [labeled]` and
guards its job with `contains(github.event.pull_request.labels.*.name,
'ok-to-extra-test')`. The guard checks the *cumulative* `labels[]` state, not
whether *this* event's `event.label.name == 'ok-to-extra-test'`. The custom
label `ok-to-extra-test` is **not** in Prow's auto-strip list (only built-in
`ok-to-test` is), so it persists across force-pushes. The checkout pins to
`event.pull_request.head.sha` — the live head SHA at firing time. Therefore:
after the maintainer applies `ok-to-extra-test` to benign SHA `A`, an attacker
force-pushes a malicious SHA `B`, and any subsequent label change (routine
triage labels like `kind/cleanup`, `area/runtime`, etc.) re-fires the workflow
on `B` with all secrets in env. The malicious Makefile exfiltrates them.

## Repo contents

| File | Purpose |
|---|---|
| `.github/workflows/functional_extra.yml` | Vulnerable workflow (mirrors upstream structure & SHA pins) |
| `Makefile` | Benign initial Makefile that the workflow's `make` step would build |
| `exploit-artifacts/Makefile.malicious` | Replacement Makefile the attacker force-pushes |
| `STEPS.md` | Step-by-step reproduction guide |

## See `STEPS.md` for the runtime reproduction.

