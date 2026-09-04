#!/usr/bin/env bash
# ==============================================================================
# Script: validate-environment.sh
# Purpose: Comprehensive read-only audit of OS, resources, CLI tools & services
# Notice: DOES NOT INSTALL ANYTHING. Pure verification.
# ==============================================================================
set -u

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

log_pass() {
  echo -e "[\033[32mPASS\033[0m] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

log_warn() {
  echo -e "[\033[33mWARN\033[0m] $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

log_fail() {
  echo -e "[\033[31mFAIL\033[0m] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

log_skip() {
  echo -e "[\033[34mSKIP\033[0m] $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

echo "=========================================================="
echo "          DEVOPS ENVIRONMENT VALIDATION SUITE            "
echo "=========================================================="

echo -e "\n--- [1/4] OPERATING SYSTEM & HARDWARE AUDIT ---"

# OS Check
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
    log_pass "Operating System: Ubuntu 24.04 LTS ($VERSION_CODENAME)"
  elif [[ "$ID" == "ubuntu" ]]; then
    log_warn "Operating System: Ubuntu $VERSION_ID (Training baseline is 24.04 LTS)"
  else
    log_fail "Operating System is not Ubuntu ($ID $VERSION_ID detected)"
  fi
else
  log_fail "Cannot detect OS distribution (/etc/os-release missing)"
fi

# CPU Check
CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
if [ "$CPU_CORES" -ge 4 ]; then
  log_pass "CPU Cores: $CPU_CORES (>= 4 cores recommended)"
elif [ "$CPU_CORES" -ge 2 ]; then
  log_warn "CPU Cores: $CPU_CORES (Minimum acceptable is 2 cores; 4+ recommended)"
else
  log_fail "CPU Cores: $CPU_CORES (Insufficient CPU for containerized stacks)"
fi

# RAM Check
TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo 0)
if [ "$TOTAL_RAM_MB" -ge 15000 ]; then
  log_pass "System RAM: ${TOTAL_RAM_MB} MB (~16 GB detected)"
elif [ "$TOTAL_RAM_MB" -ge 7500 ]; then
  log_pass "System RAM: ${TOTAL_RAM_MB} MB (~8 GB detected - 7-profile switching required)"
else
  log_fail "System RAM: ${TOTAL_RAM_MB} MB (Less than 8 GB; heavy profiles will fail)"
fi

# Disk Check
FREE_DISK_GB=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub("G","",$4); print $4}' || echo 0)
if [ "$FREE_DISK_GB" -ge 30 ]; then
  log_pass "Free Root Disk Space: ${FREE_DISK_GB} GB (>= 30 GB)"
elif [ "$FREE_DISK_GB" -ge 15 ]; then
  log_warn "Free Root Disk Space: ${FREE_DISK_GB} GB (Low disk space; clean images frequently)"
else
  log_fail "Free Root Disk Space: ${FREE_DISK_GB} GB (< 15 GB available)"
fi

# Kernel Tuning
VM_MAP=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
if [ "$VM_MAP" -ge 262144 ]; then
  log_pass "Kernel Parameter vm.max_map_count: $VM_MAP (Elasticsearch 8.17 ready)"
else
  log_warn "Kernel Parameter vm.max_map_count: $VM_MAP (Elasticsearch requires >= 262144)"
fi

# Network / DNS Check
if curl -sf --connect-timeout 3 https://www.google.com >/dev/null; then
  log_pass "Internet Connectivity & DNS Resolution: Verified"
else
  log_fail "Internet Connectivity or DNS Resolution Failed"
fi

echo -e "\n--- [2/4] CLI TOOLCHAINS & VERSIONS ---"

# Git
if command -v git &>/dev/null; then
  GIT_VER=$(git --version | awk '{print $3}')
  log_pass "Git: v$GIT_VER"
else
  log_fail "Git is not installed"
fi

# Docker Engine
if command -v docker &>/dev/null; then
  DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || true)
  if [ -n "$DOCKER_VER" ]; then
    log_pass "Docker Engine: v$DOCKER_VER (Daemon Active & Accessible)"
  else
    log_warn "Docker CLI installed but daemon not accessible by $USER"
  fi
else
  log_fail "Docker Engine is not installed"
fi

# Docker Compose
if docker compose version &>/dev/null; then
  COMPOSE_VER=$(docker compose version --short 2>/dev/null || true)
  log_pass "Docker Compose: v$COMPOSE_VER"
else
  log_fail "Docker Compose (v2 plugin) is not installed"
fi

# Terraform
if command -v terraform &>/dev/null; then
  TF_VER=$(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || terraform version | head -n1 | awk '{print $2}')
  log_pass "Terraform: $TF_VER"
else
  log_fail "Terraform is not installed"
fi

# kubectl
if command -v kubectl &>/dev/null; then
  KUBECTL_VER=$(kubectl version --client -o json 2>/dev/null | jq -r .clientVersion.gitVersion 2>/dev/null || echo "installed")
  log_pass "kubectl: $KUBECTL_VER (Target: v1.31.x)"
else
  log_fail "kubectl is not installed"
fi

# kind
if command -v kind &>/dev/null; then
  KIND_VER=$(kind version 2>/dev/null | awk '{print $2}')
  log_pass "kind: $KIND_VER (Target: v0.30.0)"
else
  log_fail "kind is not installed"
fi

# Helm
if command -v helm &>/dev/null; then
  HELM_VER=$(helm version --short 2>/dev/null)
  log_pass "Helm: $HELM_VER"
else
  log_fail "Helm is not installed"
fi

# Trivy
if command -v trivy &>/dev/null; then
  TRIVY_VER=$(trivy --version 2>/dev/null | head -n1 | awk '{print $2}')
  log_pass "Trivy: v$TRIVY_VER (Target: v0.74.0)"
else
  log_fail "Trivy is not installed"
fi

echo -e "\n--- [3/4] DEVOPS SERVICE ENDPOINTS (ACROSS 7 PROFILES) ---"

check_endpoint() {
  local name="$1"
  local url="$2"
  local expected="$3"
  if curl -sf --connect-timeout 2 "$url" 2>/dev/null | grep -q "$expected"; then
    log_pass "$name: Healthy ($url responded)"
  elif curl -sf --connect-timeout 2 -I "$url" &>/dev/null; then
    log_pass "$name: Responding ($url returned HTTP status)"
  else
    log_skip "$name: Inactive or not started (Normal if profile is idle)"
  fi
}

check_endpoint "Jenkins CI (jenkins-ci / secure-ci)" "http://localhost:8080/login" "Jenkins"
check_endpoint "SonarQube Community (secure-ci)" "http://localhost:9000/api/system/status" "UP"
check_endpoint "Harbor Registry (secure-ci)" "http://localhost:8082/api/v2.0/ping" "pong"
check_endpoint "GitLab CE (gitlab-ci)" "http://localhost:8081/-/health" "OK"
check_endpoint "Prometheus (monitoring)" "http://localhost:9090/-/healthy" "Healthy"
check_endpoint "Grafana (monitoring)" "http://localhost:3000/api/health" "ok"
check_endpoint "Alertmanager (monitoring)" "http://localhost:9093/-/healthy" "OK"
check_endpoint "Elasticsearch 8.17 (logging)" "http://localhost:9200/_cluster/health" "status"
check_endpoint "Kibana 8.17 (logging)" "http://localhost:5601/api/status" "status"
check_endpoint "Headlamp UI (kubernetes)" "http://localhost:8088/" "Headlamp"

# kind Cluster check
if command -v kubectl &>/dev/null && kubectl cluster-info &>/dev/null; then
  log_pass "Kubernetes Cluster (kubernetes profile): Active & Ready"
else
  log_skip "Kubernetes Cluster: Idle (Start 'kubernetes' profile to test)"
fi

echo -e "\n=========================================================="
echo "          ENVIRONMENT VALIDATION SUMMARY                 "
echo "=========================================================="
echo "  PASS : $PASS_COUNT"
echo "  WARN : $WARN_COUNT"
echo "  FAIL : $FAIL_COUNT"
echo "  SKIP : $SKIP_COUNT"
echo "----------------------------------------------------------"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  echo -e "  STATUS: \033[32mREADY FOR TRAINING (OPTIMAL)\033[0m"
  EXIT_CODE=0
elif [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "  STATUS: \033[33mREADY FOR TRAINING (WITH WARNINGS)\033[0m"
  EXIT_CODE=0
else
  echo -e "  STATUS: \033[31mNOT READY - RESOLVE FAILED CHECKS FIRST\033[0m"
  EXIT_CODE=1
fi
echo "=========================================================="

exit $EXIT_CODE
