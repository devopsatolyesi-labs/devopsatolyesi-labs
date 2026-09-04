#!/usr/bin/env bash
set -euo pipefail
echo "==> Cleaning up Lab LOG-02 containers and data..."
docker compose down -v --remove-orphans 2>/dev/null || true
echo "==> Lab LOG-02 clean."
