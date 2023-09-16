import flask
from flask import request, Flask
import waitress as maid
import json
import datetime
import asyncio

app = Flask(__name__)

app: flask.Flask = flask.Flask(__name__)



@app.route('/', methods=['GET'])
def humandata():
    return flask.render_template("index.html")

if __name__ == "__main__":
    # maid.serve(app, host="0.0.0.0", port=7171)
    app.run(host="0.0.0.0", port=4040, debug=True)
