#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-10: Helm values.yaml..."
test -f values.yaml
echo "[PASS] Helm values file exists."
