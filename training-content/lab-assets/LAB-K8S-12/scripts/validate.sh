#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-12: Capstone manifests..."
kubectl apply --dry-run=client -f backend-deployment.yaml
kubectl apply --dry-run=client -f frontend-deployment.yaml
kubectl apply --dry-run=client -f ingress.yaml
echo "[PASS] All Capstone manifests are valid."
