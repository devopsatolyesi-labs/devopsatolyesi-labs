#!/usr/bin/env bash
# ==============================================================================
# Script: cleanup.sh
# Purpose: Gracefully tears down the monitoring release and namespace
# ==============================================================================
set -euo pipefail

echo "==> Cleaning up Centralized Monitoring Stack..."

TARGET_DIR="${HOME}/devops-workspace/labs/LAB-TF-04"

if [ -d "$TARGET_DIR" ]; then
  echo "==> Running terraform destroy in $TARGET_DIR..."
  (cd "$TARGET_DIR" && terraform destroy -auto-approve || true)
fi

echo "==> Deleting sample application..."
kubectl delete -f "${TARGET_DIR}/sample-app.yaml" --ignore-not-found=true 2>/dev/null || true

echo "==> Removing namespace monitoring if remaining..."
kubectl delete namespace monitoring --ignore-not-found=true 2>/dev/null || true

echo "==> Cleanup completed successfully."
