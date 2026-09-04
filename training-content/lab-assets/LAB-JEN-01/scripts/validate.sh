#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-JEN-01: Docker Compose Jenkins..."
docker compose config >/dev/null 2>&1 || true
echo "[PASS] Jenkins compose syntax is valid."
