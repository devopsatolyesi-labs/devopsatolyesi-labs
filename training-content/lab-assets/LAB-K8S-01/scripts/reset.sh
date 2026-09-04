#!/usr/bin/env bash
set -euo pipefail
echo "==> Resetting LAB-K8S-01..."
kubectl config use-context kind-devops-cluster || true
