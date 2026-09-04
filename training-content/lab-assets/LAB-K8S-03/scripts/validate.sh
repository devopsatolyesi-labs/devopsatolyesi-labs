#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-03: Ingress & PDB..."
kubectl apply --dry-run=client -f ingress.yaml
echo "[PASS] Ingress and PodDisruptionBudget manifests validated."
