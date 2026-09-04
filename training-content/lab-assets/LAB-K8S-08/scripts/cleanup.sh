#!/usr/bin/env bash
set -euo pipefail
kubectl delete pod storage-demo --ignore-not-found=true
kubectl delete pvc storage-claim --ignore-not-found=true
echo "[PASS] Cleanup complete."
