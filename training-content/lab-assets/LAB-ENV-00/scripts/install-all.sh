#!/usr/bin/env bash
# ==============================================================================
# Script: install-all.sh
# Purpose: Automated fast preparation / environment recovery tool
# Notice: This is NOT an alternative to learning manual installation!
#         Use for initial classroom staging or rapid lab VM recovery.
# ==============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_pass() { echo -e "[\033[32mPASS\033[0m] $1"; }
log_warn() { echo -e "[\033[33mWARN\033[0m] $1"; }
log_fail() { echo -e "[\033[31mFAIL\033[0m] $1"; }
log_inst() { echo -e "[\033[34mINSTALL\033[0m] $1"; }

echo "=========================================================="
echo "      DEVOPS TRAINING AUTOMATED FAST-PREP / RECOVERY     "
echo "=========================================================="

# 1. OS Check
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
    log_pass "Ubuntu 24.04 LTS detected ($VERSION_CODENAME)"
  elif [[ "$ID" == "ubuntu" ]]; then
    log_warn "Ubuntu $VERSION_ID detected (Target baseline is 24.04 LTS)"
  else
    log_fail "Non-Ubuntu system ($ID). Halting automated setup."
    exit 1
  fi
else
  log_fail "Cannot read /etc/os-release. Halting."
  exit 1
fi

# 2. Architecture Check
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$ARCH" in
  amd64|x86_64) log_pass "Architecture: x86_64 (amd64)" ;;
  arm64|aarch64) log_pass "Architecture: arm64 (aarch64)" ;;
  *) log_fail "Unsupported CPU Architecture: $ARCH" && exit 1 ;;
esac

# 3. Internet Connectivity
if curl -sf --connect-timeout 4 https://www.google.com >/dev/null; then
  log_pass "Internet & DNS connectivity verified"
else
  log_fail "No internet access. Package downloads will fail."
  exit 1
fi

# 4. Hardware Resources
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM_MB" -ge 7500 ]; then
  log_pass "System RAM: ${TOTAL_RAM_MB} MB (Meets >= 8 GB requirement)"
else
  log_warn "System RAM: ${TOTAL_RAM_MB} MB (Low memory; only run 1 of 7 profiles at a time)"
fi

FREE_DISK_GB=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$FREE_DISK_GB" -ge 20 ]; then
  log_pass "Free Disk Space: ${FREE_DISK_GB} GB"
else
  log_warn "Free Disk Space: ${FREE_DISK_GB} GB (Recommend at least 25 GB free)"
fi

echo -e "\n--- CHECKING & INSTALLING TOOLCHAINS (IDEMPOTENT) ---"

# Base Tools
if command -v git &>/dev/null && command -v jq &>/dev/null; then
  log_pass "Git and Base utilities already installed"
else
  log_inst "Base utilities missing. Installing..."
  bash "${SCRIPT_DIR}/install-base-tools.sh"
  log_pass "Base utilities installed"
fi

# Docker Engine & Compose
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || docker --version | awk '{print $3}' | tr -d ',')
  log_pass "Docker Engine installed (v$DOCKER_VER)"
  log_pass "Docker Compose installed"
else
  log_inst "Docker Engine or Compose missing. Installing..."
  bash "${SCRIPT_DIR}/install-docker.sh"
  log_pass "Docker Engine installed"
  log_pass "Docker Compose installed"
fi

# Terraform
if command -v terraform &>/dev/null; then
  TF_VER=$(terraform version | head -n1 | awk '{print $2}')
  log_pass "Terraform installed ($TF_VER)"
else
  log_inst "Terraform missing. Installing..."
  bash "${SCRIPT_DIR}/install-terraform.sh"
  log_pass "Terraform installed"
fi

# Kubernetes Toolchain (kubectl, kind, helm)
K8S_MISSING=0
command -v kubectl &>/dev/null || K8S_MISSING=1
command -v kind &>/dev/null || K8S_MISSING=1
command -v helm &>/dev/null || K8S_MISSING=1

if [ "$K8S_MISSING" -eq 0 ]; then
  log_pass "kubectl installed ($(kubectl version --client --output=json 2>/dev/null | jq -r .clientVersion.gitVersion 2>/dev/null || echo 'installed'))"
  log_pass "kind installed ($(kind version | awk '{print $2}'))"
  log_pass "Helm installed ($(helm version --short 2>/dev/null || echo 'installed'))"
else
  log_inst "Kubernetes tools (kubectl/kind/helm) incomplete. Installing..."
  bash "${SCRIPT_DIR}/install-kubernetes-tools.sh"
  log_pass "kubectl installed"
  log_pass "kind installed"
  log_pass "Helm installed"
fi

# Security Toolchains (Trivy, Argo CD CLI)
SEC_MISSING=0
command -v trivy &>/dev/null || SEC_MISSING=1
command -v argocd &>/dev/null || SEC_MISSING=1

if [ "$SEC_MISSING" -eq 0 ]; then
  log_pass "Trivy installed ($(trivy --version 2>/dev/null | head -n1 | awk '{print $2}'))"
  log_pass "Argo CD CLI installed"
else
  log_inst "Security & GitOps tools (Trivy/ArgoCD) missing. Installing..."
  bash "${SCRIPT_DIR}/install-security-tools.sh"
  log_pass "Trivy installed"
  log_pass "Argo CD CLI installed"
fi

# Prepare 7 Service Profiles
echo -e "\n--- PREPARING 7 SERVICE PROFILES DEFINITIONS ---"
bash "${SCRIPT_DIR}/prepare-service-profiles.sh"
log_pass "7 Service profiles generated in ~/devops-workspace/profiles"

echo -e "\n--- RUNNING FINAL ENVIRONMENT AUDIT ---"
bash "${SCRIPT_DIR}/validate-environment.sh"
