#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-MON-02: Alert rules syntax..."
docker run --rm -v "$(pwd)/alert.rules.yml:/rules.yml" prom/prometheus:v3.13.2 check rules /rules.yml
echo "[PASS] Prometheus alert rules validated successfully."
