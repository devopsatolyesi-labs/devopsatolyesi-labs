#!/usr/bin/env bash
set -euo pipefail
kubectl delete pod my-first-pod --ignore-not-found=true
echo "[PASS] Cleanup complete."
