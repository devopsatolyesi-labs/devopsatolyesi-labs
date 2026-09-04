#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-05: Service manifest..."
kubectl apply --dry-run=client -f service.yaml
echo "[PASS] Service manifest is valid."
