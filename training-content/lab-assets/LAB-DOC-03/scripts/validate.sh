#!/usr/bin/env bash
# ==============================================================================
# Script: validate.sh
# Purpose: Validates Docker Image Minimization & Registry Tagging (LAB-DOC-03)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "  VALIDATING IMAGE MINIMIZATION & REGISTRY PUSH (LAB-DOC-03) "
echo "=========================================================="

PASS=0
FAIL=0

log_pass() { echo -e "[\033[32mPASS\033[0m] $1"; PASS=$((PASS+1)); }
log_fail() { echo -e "[\033[31mFAIL\033[0m] $1"; FAIL=$((FAIL+1)); }

# 1. Check Container Health
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/healthz 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
  log_pass "Optimized container responds on port 8000 with HTTP 200 (UP)."
else
  log_fail "Optimized container health check returned HTTP $HTTP_STATUS (expected 200)."
fi

# 2. Check Image Sizes
if docker image inspect devops-demo-api:slim >/dev/null 2>&1; then
  SLIM_SIZE_BYTES=$(docker image inspect devops-demo-api:slim --format '{{.Size}}')
  SLIM_MB=$((SLIM_SIZE_BYTES / 1024 / 1024))
  if [ "$SLIM_MB" -lt 250 ]; then
    log_pass "Single-Stage Slim image size is ${SLIM_MB} MB (< 250 MB target)."
  else
    log_fail "Single-Stage Slim image is unexpectedly large: ${SLIM_MB} MB."
  fi
else
  log_fail "Image 'devops-demo-api:slim' not found locally."
fi

if docker image inspect devops-demo-api:multistage >/dev/null 2>&1; then
  MULTI_SIZE_BYTES=$(docker image inspect devops-demo-api:multistage --format '{{.Size}}')
  MULTI_MB=$((MULTI_SIZE_BYTES / 1024 / 1024))
  if [ "$MULTI_MB" -lt 80 ]; then
    log_pass "Multi-Stage Minimal image size is ${MULTI_MB} MB (< 80 MB target!)."
  else
    log_fail "Multi-Stage image is unexpectedly large: ${MULTI_MB} MB."
  fi
else
  log_fail "Image 'devops-demo-api:multistage' not found locally."
fi

# 3. Check the remote registry manifest, not only the local tag.
REGISTRY=${HARBOR_REGISTRY:-localhost:8082}
REGISTRY_REF="$REGISTRY/devops/order-api:1.0.0"
if docker manifest inspect --insecure "$REGISTRY_REF" >/dev/null 2>&1; then
  log_pass "Harbor manifest verified: $REGISTRY_REF"
else
  log_fail "Harbor manifest '$REGISTRY_REF' not found or authentication failed."
fi

echo "----------------------------------------------------------"
echo "  SUMMARY: PASS=$PASS | FAIL=$FAIL"
echo "----------------------------------------------------------"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  RESULT: \033[32mIMAGE MINIMIZATION & REGISTRY PUBLISHING VALIDATED\033[0m"
  exit 0
else
  echo -e "  RESULT: \033[31mVALIDATION FAILED\033[0m"
  exit 1
fi
