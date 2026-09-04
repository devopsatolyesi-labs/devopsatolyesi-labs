#!/usr/bin/env bash
set -euo pipefail

echo "==> Stopping the lab-doc-13 Docker Compose stack..."
docker compose -p lab-doc-13 --profile "*" -f compose.yaml -f compose.prod.yaml \
  down -v --remove-orphans 2>/dev/null || true
echo "==> Cleanup complete."
