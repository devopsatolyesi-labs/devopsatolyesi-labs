#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-ARG-01: Argo CD Application manifest..."
kubectl apply --dry-run=client -f application.yaml
echo "[PASS] Argo CD Application manifest syntax verified."
