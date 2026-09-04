#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-11: Troubleshooting manifest..."
kubectl apply --dry-run=client -f broken-app.yaml
echo "[PASS] Manifest is syntactically valid."
