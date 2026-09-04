#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-K8S-01: kind cluster and nodes..."
kubectl get nodes
echo "[PASS] Kubernetes cluster is accessible via kubectl."
