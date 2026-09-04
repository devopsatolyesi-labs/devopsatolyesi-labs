#!/usr/bin/env bash
set -euo pipefail
kubectl delete deployment order-api --ignore-not-found=true
echo "[PASS] Cleanup complete."
