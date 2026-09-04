#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-04: Deployment and rollout strategy..."
kubectl apply --dry-run=client -f deployment.yaml
echo "[PASS] RollingUpdate manifest is valid."
