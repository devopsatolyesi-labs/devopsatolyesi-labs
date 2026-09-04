#!/usr/bin/env bash
# ==============================================================================
# DevOps Atölyesi — Elasticsearch ILM & Index Template Initializer
# ==============================================================================
set -euo pipefail

ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Waiting for Elasticsearch to become ready at ${ES_URL}..."
MAX_RETRIES=30
COUNT=0
until curl -s -f "${ES_URL}/_cluster/health" >/dev/null 2>&1; do
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -gt "$MAX_RETRIES" ]; then
    echo "ERROR: Elasticsearch did not become ready within timeout."
    exit 1
  fi
  echo "    Attempt ${COUNT}/${MAX_RETRIES}... waiting 5s"
  sleep 5
done

echo "==> Elasticsearch is UP and responsive."

# 1. Apply Index Lifecycle Management (ILM) Policy
echo "==> Applying ILM policy 'logs-policy'..."
curl -s -X PUT "${ES_URL}/_ilm/policy/logs-policy" \
  -H "Content-Type: application/json" \
  -d @"${BASE_DIR}/elasticsearch/ilm-policy.json" | grep -q '\"acknowledged\":true' && echo "    [OK] ILM policy configured." || echo "    [WARN] ILM policy response received."

# 2. Apply Index Template
echo "==> Applying Index Template 'logs-template'..."
curl -s -X PUT "${ES_URL}/_index_template/logs-template" \
  -H "Content-Type: application/json" \
  -d @"${BASE_DIR}/elasticsearch/index-template.json" | grep -q '\"acknowledged\":true' && echo "    [OK] Index template configured." || echo "    [WARN] Index template response received."

echo "==> Elasticsearch initialization complete."

echo "==> Applying metrics index template..."
curl -s -X PUT "${ES_URL}/_index_template/devops-metrics-template" \
  -H "Content-Type: application/json" \
  -d @"${BASE_DIR}/elasticsearch/metrics-index-template.json" | grep -q '\"acknowledged\":true' \
  && echo "    [OK] Metrics template configured." \
  || echo "    [WARN] Metrics template response received."
