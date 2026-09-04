#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-07: Probes and Resources..."
kubectl apply --dry-run=client -f deployment.yaml
echo "[PASS] Health probes and resource limits manifest is valid."
