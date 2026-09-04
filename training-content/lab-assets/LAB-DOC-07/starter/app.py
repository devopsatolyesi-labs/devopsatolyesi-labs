import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({
        "service": "Order Management API",
        "version": "1.0.0",
        "hostname": socket.gethostname(),
        "status": "healthy"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
