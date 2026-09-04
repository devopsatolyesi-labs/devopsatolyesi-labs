#!/usr/bin/env bash
# ==============================================================================
# DevOps Atölyesi — ELK Stack Cleanup Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Stopping ELK Stack containers and removing volumes..."
(cd "${BASE_DIR}" && docker compose down -v --remove-orphans)

echo "==> Cleanup complete."
