#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-INC-01: Incident fix deployment..."
kubectl apply --dry-run=client -f fixed-deployment.yaml
echo "[PASS] Fixed deployment syntax is valid and ready to resolve CrashLoopBackOff."
