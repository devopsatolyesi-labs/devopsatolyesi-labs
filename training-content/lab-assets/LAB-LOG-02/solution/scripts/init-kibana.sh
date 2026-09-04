#!/usr/bin/env bash
# ==============================================================================
# DevOps Atölyesi — Kibana Data View & Dashboard Initializer
# ==============================================================================
set -euo pipefail

KIBANA_URL="${KIBANA_URL:-http://localhost:5601}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Waiting for Kibana to become ready at ${KIBANA_URL}..."
MAX_RETRIES=40
COUNT=0
until curl -s -f "${KIBANA_URL}/api/status" 2>/dev/null | grep -q '"level":"available"'; do
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -gt "$MAX_RETRIES" ]; then
    echo "ERROR: Kibana did not become available within timeout."
    exit 1
  fi
  echo "    Attempt ${COUNT}/${MAX_RETRIES}... waiting 5s"
  sleep 5
done

echo "==> Kibana is UP and available."

# 1. Create deterministic log and metric data views.
for data_view_file in data-view-logs.json data-view-nginx.json data-view-metrics.json; do
  echo "==> Applying ${data_view_file}..."
  curl --fail --silent --show-error -X POST "${KIBANA_URL}/api/data_views/data_view" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d @"${BASE_DIR}/kibana/${data_view_file}" >/dev/null
done

# 2. Import the version-pinned Dashboard, Map, Canvas and Vega panels.
echo "==> Importing advanced observability saved objects..."
IMPORT_RESPONSE=$(curl --fail --silent --show-error \
  -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form "file=@${BASE_DIR}/kibana/advanced-observability.ndjson")
echo "${IMPORT_RESPONSE}" | grep -q '"success":true' || {
  echo "${IMPORT_RESPONSE}" >&2
  exit 1
}
echo "    [OK] Dashboard, GeoMap and Canvas imported."

# Canvas workpad export is applied last because Canvas requires explicit page
# and element type metadata in 8.17.x.
CANVAS_RESPONSE=$(curl --fail --silent --show-error \
  -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form "file=@${BASE_DIR}/kibana/canvas-workpad.ndjson")
echo "${CANVAS_RESPONSE}" | grep -q '"success":true' || {
  echo "${CANVAS_RESPONSE}" >&2
  exit 1
}
echo "    [OK] Canvas page and element metadata verified."

echo "==> Kibana configuration complete. Open Kibana at http://localhost:5601"
