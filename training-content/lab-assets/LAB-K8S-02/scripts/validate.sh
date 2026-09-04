#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-02: Pod syntax and status..."
kubectl apply --dry-run=client -f pod.yaml
echo "[PASS] Pod manifest syntax is valid."
