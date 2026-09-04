#!/usr/bin/env bash
# ==============================================================================
# Script: reset.sh
# Purpose: Resets student workspace to clean starter templates
# ==============================================================================
set -euo pipefail

TARGET_DIR="${HOME}/devops-workspace/labs/LAB-TF-04"
ASSETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Tearing down existing resources..."
bash "${ASSETS_DIR}/scripts/cleanup.sh"

echo "==> Re-initializing starter files into $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
cp -r "${ASSETS_DIR}/starter/"* "$TARGET_DIR/" 2>/dev/null || true

echo "==> LAB-TF-04 workspace has been reset to initial state."
