#!/usr/bin/env bash
# ==============================================================================
# Script: cleanup.sh
# Purpose: Cleans containers and images created during LAB-DOC-03
# ==============================================================================
set -euo pipefail

echo "==> Stopping and removing demo containers..."
docker rm -f demo-api-container 2>/dev/null || true

echo "==> Removing test images..."
docker rmi devops-demo-api:bloated devops-demo-api:slim devops-demo-api:multistage 2>/dev/null || true
registry=${HARBOR_REGISTRY:-localhost:8082}
docker rmi "$registry/devops/order-api:1.0.0" 2>/dev/null || true

echo "==> Cleanup complete."
