#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-06: ConfigMap and Secret manifests..."
kubectl apply --dry-run=client -f configmap.yaml
kubectl apply --dry-run=client -f secret.yaml
echo "[PASS] ConfigMap and Secret manifests are valid."
