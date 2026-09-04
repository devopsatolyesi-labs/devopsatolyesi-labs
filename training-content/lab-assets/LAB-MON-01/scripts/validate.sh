#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-MON-01: Prometheus configuration..."
docker run --rm -v "$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml" prom/prometheus:v3.13.2 check config /etc/prometheus/prometheus.yml
echo "[PASS] Prometheus configuration syntax verified."
