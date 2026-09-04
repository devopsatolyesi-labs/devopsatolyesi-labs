#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-09: Ingress manifest..."
kubectl apply --dry-run=client -f ingress.yaml
echo "[PASS] Ingress manifest is valid."
