#!/usr/bin/env bash
set -euo pipefail
kubectl delete namespace lab-k8s-08 --ignore-not-found=true
kubectl delete pv lab-k8s-08-local-pv --ignore-not-found=true
docker exec kind-control-plane rm -rf /tmp/lab-k8s-08
echo "[PASS] Cleanup complete."
