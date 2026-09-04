#!/usr/bin/env bash
set -euo pipefail
kubectl delete deployment misconfigured-app --ignore-not-found=true
echo "[PASS] Cleanup complete."
