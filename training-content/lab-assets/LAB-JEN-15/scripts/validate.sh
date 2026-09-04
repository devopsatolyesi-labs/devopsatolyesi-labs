#!/usr/bin/env bash
set -euo pipefail
test -f app/main.py
test -f tests/test_main.py
test -f Dockerfile
test -f k8s/deployment.yaml
echo "[PASS] All Capstone assets exist."
