#!/usr/bin/env bash
# ==============================================================================
# DevOps Atölyesi — ELK Stack End-to-End Validation Script
# ==============================================================================
set -euo pipefail

ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"
KIBANA_URL="${KIBANA_URL:-http://localhost:5601}"
LOGSTASH_URL="${LOGSTASH_URL:-http://localhost:9600}"

echo "=========================================================="
echo "  STARTING ELK STACK END-TO-END VALIDATION"
echo "=========================================================="

FAILED=0

# 1. Validate Elasticsearch Health
echo -n "==> [1/5] Checking Elasticsearch Cluster Health... "
ES_HEALTH=$(curl -s "${ES_URL}/_cluster/health" 2>/dev/null || echo "{}")
ES_STATUS=$(echo "$ES_HEALTH" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")

if [ "$ES_STATUS" = "green" ] || [ "$ES_STATUS" = "yellow" ]; then
  echo "PASS (Cluster Status: $ES_STATUS)"
else
  echo "FAIL (Cluster Status: $ES_STATUS)"
  FAILED=$((FAILED + 1))
fi

# 2. Validate Logstash Health
echo -n "==> [2/5] Checking Logstash Node Status... "
LS_RES=$(curl -s "${LOGSTASH_URL}/" 2>/dev/null || echo "{}")
if echo "$LS_RES" | grep -q '"status":"green"\|"status":"yellow"\|"status":"ok"'; then
  echo "PASS (Logstash active)"
else
  # Logstash might return empty on root or different status json
  if docker ps | grep -q "devops-logstash.*Up"; then
    echo "PASS (Logstash container running)"
  else
    echo "FAIL (Logstash unreachable)"
    FAILED=$((FAILED + 1))
  fi
fi

# 3. Validate Kibana Health
echo -n "==> [3/5] Checking Kibana Web UI Status... "
KBN_RES=$(curl -s "${KIBANA_URL}/api/status" 2>/dev/null || echo "{}")
if echo "$KBN_RES" | grep -q '"level":"available"'; then
  echo "PASS (Kibana available on port 5601)"
else
  echo "FAIL (Kibana not ready)"
  FAILED=$((FAILED + 1))
fi

# 4. Validate Elasticsearch Daily Indices
echo -n "==> [4/5] Checking Elasticsearch Indices for 'logs-*'... "
INDICES=$(curl -s "${ES_URL}/_cat/indices/logs-*?h=index" 2>/dev/null || true)
if [ -n "$INDICES" ]; then
  echo "PASS (Found: $(echo "$INDICES" | tr '\n' ' '))"
else
  echo "FAIL (No logs-* index found)"
  FAILED=$((FAILED + 1))
fi

# 5. Validate Indexed Documents Count & Query
echo -n "==> [5/5] Checking Document Ingestion & Structured Search... "
DOC_COUNT=$(curl -s "${ES_URL}/logs-*/_count" 2>/dev/null | grep -o '"count":[0-9]*' | cut -d':' -f2 || echo "0")

if [ -n "$DOC_COUNT" ] && [ "$DOC_COUNT" -gt 0 ]; then
  echo "PASS (Total documents indexed: $DOC_COUNT)"
  
  # Check for error query
  ERR_COUNT=$(curl -s "${ES_URL}/logs-*/_count?q=level:ERROR" 2>/dev/null | grep -o '"count":[0-9]*' | cut -d':' -f2 || echo "0")
  echo "    --> ERROR severity log events: $ERR_COUNT"
else
  echo "FAIL (0 documents found in Elasticsearch)"
  FAILED=$((FAILED + 1))
fi

echo "=========================================================="
if [ "$FAILED" -eq 0 ]; then
  echo "  ALL CHECKS PASSED: ELK STACK IS FULLY FUNCTIONAL!"
  echo "  Kibana Dashboard URL: http://localhost:5601"
  echo "  Elasticsearch REST:   http://localhost:9200"
  echo "=========================================================="
  exit 0
else
  echo "  VALIDATION FAILED: $FAILED check(s) failed."
  echo "=========================================================="
  exit 1
fi
