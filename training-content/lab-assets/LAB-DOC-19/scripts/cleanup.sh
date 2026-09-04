#!/usr/bin/env bash
set -euo pipefail

echo "==> Cleaning up LAB-DOC-05..."
docker compose -p lab-doc-05 down -v --remove-orphans 2>/dev/null || true
echo "Cleanup completed."
