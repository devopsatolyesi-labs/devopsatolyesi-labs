#!/usr/bin/env bash
set -euo pipefail
kubectl delete deployment payment-service --ignore-not-found=true
echo "[PASS] Cleanup complete."
