#!/usr/bin/env bash
# ==============================================================================
# DevOps Atölyesi — ELK Stack Multi-Channel Log Generator & Traffic Simulator
# Ingests logs through:
#   1. Express Order API (HTTP 3001)
#   2. Logstash HTTP Endpoint (HTTP 8085)
#   3. Logstash TCP Socket (TCP 5000)
#   4. Direct Elasticsearch REST Indexing (HTTP 9200)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "  GENERATING TELEMETRY & LOGS ACROSS ALL ELK CHANNELS"
echo "=========================================================="

# 1. Traffic to Express Order API (stdout -> Filebeat + TCP to Logstash)
echo "==> 1. Generating HTTP application traffic to Order API (port 3001)..."
for i in {1..5}; do
  curl -s -X POST http://localhost:3001/api/orders \
    -H "Content-Type: application/json" \
    -d "{\"customer\": \"student_$i\", \"total_amount\": $((i * 25)), \"items\": [\"course_devops\", \"lab_access\"]}" >/dev/null || true
  sleep 0.5
done

# Error scenario to Order API
echo "==> 2. Triggering simulated error scenarios..."
curl -s -X POST http://localhost:3001/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customer": "fail_test_user", "fail_payment": true}' >/dev/null || true
curl -s http://localhost:3001/api/simulate-error >/dev/null || true

# 2. Ingest via Logstash HTTP Endpoint (port 8085 -> internal 8080)
echo "==> 3. Posting structured events directly to Logstash HTTP input (port 8085)..."
curl -s -X POST http://localhost:8085 \
  -H "Content-Type: application/json" \
  -d '{
    "service": "auth-service",
    "level": "INFO",
    "message": "User authenticated successfully via OAuth2 SSO",
    "user_id": "usr_9921",
    "client_ip": "8.8.8.8",
    "status": 200,
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }' >/dev/null || true

curl -s -X POST http://localhost:8085 \
  -H "Content-Type: application/json" \
  -d '{
    "service": "auth-service",
    "level": "ERROR",
    "message": "Invalid credentials attempt exceeded rate limit",
    "user_id": "usr_attacker",
    "client_ip": "1.1.1.1",
    "status": 429,
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }' >/dev/null || true

# 3. Direct Elasticsearch REST bulk/index
echo "==> 4. Indexing verification document directly to Elasticsearch..."
curl -s -X POST "http://localhost:9200/logs-$(date +%Y.%m.%d)/_doc" \
  -H "Content-Type: application/json" \
  -d '{
    "@timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "service": "verification-probe",
    "level": "INFO",
    "message": "ELK Stack end-to-end integration verified successfully",
    "environment": "production",
    "status": 200,
    "trace_id": "probe-check-001"
  }' >/dev/null || true

echo "==> Log generation completed successfully."
