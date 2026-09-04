#!/usr/bin/env bash
# ==============================================================================
# Script: validate.sh
# Purpose: Validates Centralized Kubernetes Monitoring deployment via Terraform & Helm
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "  VALIDATING CENTRALIZED MONITORING STACK (LAB-TF-04)    "
echo "=========================================================="

PASS=0
FAIL=0

log_pass() { echo -e "[\033[32mPASS\033[0m] $1"; PASS=$((PASS+1)); }
log_fail() { echo -e "[\033[31mFAIL\033[0m] $1"; FAIL=$((FAIL+1)); }

# 1. Namespace Check
if kubectl get namespace monitoring &>/dev/null; then
  log_pass "Namespace 'monitoring' exists and is Active."
else
  log_fail "Namespace 'monitoring' not found."
fi

# 2. Helm Release Check
if helm list -n monitoring 2>/dev/null | grep -q "kube-prometheus-stack"; then
  STATUS=$(helm list -n monitoring -o json | jq -r '.[0].status')
  if [ "$STATUS" = "deployed" ]; then
    log_pass "Helm release 'kube-prometheus-stack' is deployed."
  else
    log_fail "Helm release status is $STATUS (expected 'deployed')."
  fi
else
  log_fail "Helm release 'kube-prometheus-stack' not found in namespace 'monitoring'."
fi

# 3. Pod Health Checks
READY_PROMETHEUS=$(kubectl get statefulset -n monitoring prometheus-kube-prometheus-stack-prometheus -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
if [ "${READY_PROMETHEUS:-0}" -ge 1 ]; then
  log_pass "Prometheus StatefulSet has $READY_PROMETHEUS ready replica(s)."
else
  log_fail "Prometheus replica is not ready."
fi

READY_GRAFANA=$(kubectl get deployment -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
if [ "${READY_GRAFANA:-0}" -ge 1 ]; then
  log_pass "Grafana Deployment has $READY_GRAFANA ready replica(s)."
else
  log_fail "Grafana replica is not ready."
fi

# 4. ServiceMonitor CRD Check
if kubectl get crd servicemonitors.monitoring.coreos.com &>/dev/null; then
  log_pass "ServiceMonitor CRD is successfully registered in Kubernetes."
else
  log_fail "ServiceMonitor CRD missing."
fi

echo "----------------------------------------------------------"
echo "  SUMMARY: PASS=$PASS | FAIL=$FAIL"
echo "----------------------------------------------------------"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  RESULT: \033[32mCENTRALIZED MONITORING DEPLOYMENT VALIDATED\033[0m"
  exit 0
else
  echo -e "  RESULT: \033[31mVALIDATION FAILED - CHECK POD LOGS\033[0m"
  exit 1
fi
