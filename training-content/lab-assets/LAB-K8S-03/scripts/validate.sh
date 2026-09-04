#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-03: Deployment manifest..."
kubectl apply --dry-run=client -f deployment.yaml
echo "[PASS] Deployment manifest is valid."
