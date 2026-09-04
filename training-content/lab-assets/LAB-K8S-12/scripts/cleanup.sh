#!/usr/bin/env bash
set -euo pipefail
kubectl delete ingress capstone-ingress --ignore-not-found=true
kubectl delete deployment capstone-backend capstone-frontend --ignore-not-found=true
echo "[PASS] Cleanup complete."
