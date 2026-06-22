import os
from flask import Flask, request

app = Flask(__name__)


@app.route("/x")
def x():
    # CodeQL: py/command-line-injection (critical)
    return os.popen("echo " + request.args.get("c")).read()


@app.route("/e")
def e():
    # CodeQL: py/code-injection (critical)
    return str(eval(request.args.get("v")))
