#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-01: Deployment manifest..."
kubectl apply --dry-run=client -f deployment.yaml
echo "[PASS] Kubernetes Deployment manifest syntax is valid."
