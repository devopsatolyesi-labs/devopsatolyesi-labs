#!/usr/bin/env bash
set -euo pipefail
ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"

echo "==> Validating Lab LOG-02 (ELK Centralized Logging)..."
if ! curl -s "${ES_URL}/_cluster/health" 2>/dev/null | grep -q '"status":"green"\|"status":"yellow"'; then
  echo "FAIL: Elasticsearch cluster is not healthy."
  exit 1
fi

COUNT=$(curl -s "${ES_URL}/logs-*/_count" 2>/dev/null | grep -o '"count":[0-9]*' | cut -d':' -f2 || echo "0")
if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ]; then
  echo "PASS: Successfully verified $COUNT indexed log documents in Elasticsearch."
else
  echo "FAIL: No indexed logs found in Elasticsearch."
  exit 1
fi
