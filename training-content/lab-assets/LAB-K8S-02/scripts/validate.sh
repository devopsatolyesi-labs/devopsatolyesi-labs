#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-02: Services, ConfigMaps & Secrets..."
kubectl apply --dry-run=client -f service.yaml
echo "[PASS] Service, ConfigMap and Secret definitions are valid."
