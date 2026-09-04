#!/usr/bin/env bash
# ==============================================================================
# Script: reset.sh
# Purpose: Resets student workspace to clean starter files
# ==============================================================================
set -euo pipefail

ASSETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Cleaning existing containers and images..."
bash "${ASSETS_DIR}/scripts/cleanup.sh"

echo "==> Restoring starter templates to the current directory..."
cp -a "${ASSETS_DIR}/starter/." .

echo "==> LAB-DOC-03 reset completed."
