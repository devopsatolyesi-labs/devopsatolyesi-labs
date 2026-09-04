#!/usr/bin/env bash
set -euo pipefail
echo "==> Running Capstone Integrated Delivery Pipeline..."
echo "[1/4] Validating application syntax..."
python3 -m py_compile app/main.py
echo "[2/4] Verifying health and metrics endpoints..."
grep -q "'/healthz'" app/main.py
grep -q "'/metrics'" app/main.py
echo "[3/4] Validating Kubernetes manifest..."
kubectl apply --dry-run=client --validate=false -f gitops-manifests/
echo "[4/4] Rejecting floating image tags..."
! grep -RInE 'image:.*:(latest|dev|main)([[:space:]]|$)' gitops-manifests/
echo "==> Capstone Pipeline Execution Completed: SUCCESS"
