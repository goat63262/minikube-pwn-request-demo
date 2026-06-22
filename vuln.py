import os
from flask import Flask, request
app = Flask(__name__)

@app.route("/x")
def x():
    return os.popen("echo " + request.args.get("c")).read()

@app.route("/e")
def e():
    return str(eval(request.args.get("v")))
