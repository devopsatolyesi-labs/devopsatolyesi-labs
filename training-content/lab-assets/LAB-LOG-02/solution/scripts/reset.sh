#!/usr/bin/env bash
# ==============================================================================
# DevOps Atölyesi — ELK Stack Reset & Re-Seed Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Resetting ELK Stack environment..."
bash "${SCRIPT_DIR}/cleanup.sh"

echo "==> Starting fresh stack..."
(cd "${BASE_DIR}" && docker compose up -d --build)

echo "==> Initializing Elasticsearch ILM & Index Templates..."
bash "${SCRIPT_DIR}/init-elasticsearch.sh"

echo "==> Initializing Kibana Data Views..."
bash "${SCRIPT_DIR}/init-kibana.sh"

echo "==> Generating initial telemetry..."
bash "${SCRIPT_DIR}/generate-logs.sh"

echo "==> Validating stack..."
bash "${SCRIPT_DIR}/validate.sh"
