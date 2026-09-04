#!/usr/bin/env python3
"""
DevOps Atölyesi — Background Payment Transaction Logger Worker
Generates continuous structured telemetry, error spikes, and TCP socket stream logs.
"""
import os
import sys
import json
import time
import socket
import logging
import random
import uuid
from datetime import datetime, timezone

SERVICE_NAME = os.getenv("SERVICE_NAME", "payment-worker")
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")
LOGSTASH_HOST = os.getenv("LOGSTASH_TCP_HOST", "logstash")
LOGSTASH_PORT = int(os.getenv("LOGSTASH_TCP_PORT", "5000"))
INTERVAL = float(os.getenv("LOG_INTERVAL_SECONDS", "2.0"))

class StructuredFormatter(logging.Formatter):
    def format(self, record):
        data = {
            "@timestamp": datetime.now(timezone.utc).isoformat(),
            "service": SERVICE_NAME,
            "environment": ENVIRONMENT,
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name
        }
        if hasattr(record, "extra_fields"):
            data.update(record.extra_fields)
        return json.dumps(data)

logger = logging.getLogger(SERVICE_NAME)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(StructuredFormatter())
logger.addHandler(handler)
logger.setLevel(logging.INFO)

def send_tcp_log(payload):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2.0)
        sock.connect((LOGSTASH_HOST, LOGSTASH_PORT))
        raw_msg = json.dumps(payload) + "\n"
        sock.sendall(raw_msg.encode("utf-8"))
        sock.close()
    except Exception as e:
        # Non-blocking if Logstash is initializing
        pass

def main():
    logger.info("Payment worker service started and listening for transaction queue...", extra={"extra_fields": {"status": "INITIALIZED"}})
    tx_count = 0

    while True:
        tx_count += 1
        trace_id = f"tx-{uuid.uuid4().hex[:8]}"
        amount = round(random.uniform(10.0, 500.0), 2)
        gateway = random.choice(["Stripe", "PayPal", "Iyzico", "Adyen"])

        # Every 6th transaction simulates a failure / error
        if tx_count % 6 == 0:
            err_msg = f"Transaction #{tx_count} failed on gateway {gateway}: Gateway Timeout (HTTP 504)"
            extra = {
                "trace_id": trace_id,
                "order_id": f"ord_{1000 + tx_count}",
                "amount": amount,
                "gateway": gateway,
                "status": 504,
                "error_code": "GATEWAY_TIMEOUT",
                "level": "ERROR"
            }
            logger.error(err_msg, extra={"extra_fields": extra})
            send_tcp_log({
                "@timestamp": datetime.now(timezone.utc).isoformat(),
                "service": SERVICE_NAME,
                "environment": ENVIRONMENT,
                "level": "ERROR",
                "message": err_msg,
                **extra
            })
        else:
            success_msg = f"Transaction #{tx_count} approved via {gateway} for amount ${amount}"
            extra = {
                "trace_id": trace_id,
                "order_id": f"ord_{1000 + tx_count}",
                "amount": amount,
                "gateway": gateway,
                "status": 200,
                "level": "INFO"
            }
            logger.info(success_msg, extra={"extra_fields": extra})
            send_tcp_log({
                "@timestamp": datetime.now(timezone.utc).isoformat(),
                "service": SERVICE_NAME,
                "environment": ENVIRONMENT,
                "level": "INFO",
                "message": success_msg,
                **extra
            })

        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
