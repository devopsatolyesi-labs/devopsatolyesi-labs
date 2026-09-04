#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-08: PVC and Pod volume mounts..."
kubectl apply --dry-run=client -f pvc.yaml
kubectl apply --dry-run=client -f pod.yaml
echo "[PASS] PVC and Pod storage manifests are valid."
