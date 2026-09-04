#!/usr/bin/env bash
# ==============================================================================
# Script: validate.sh
# Purpose: Validates AWS VPC Multi-AZ Public/Private Subnet Terraform Deployment (LAB-TF-08)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "   VALIDATING AWS MULTI-AZ VPC TERRAFORM DEPLOYMENT       "
echo "                   (LAB-TF-08)                            "
echo "=========================================================="

PASS=0
FAIL=0

log_pass() { echo -e "[\033[32mPASS\033[0m] $1"; PASS=$((PASS+1)); }
log_fail() { echo -e "[\033[31mFAIL\033[0m] $1"; FAIL=$((FAIL+1)); }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}/solution" 2>/dev/null || cd "${LAB_DIR}"

# 1. Terraform Binary & Syntax Validation
if command -v terraform &>/dev/null; then
  log_pass "Terraform CLI is installed ($(terraform version -json 2>/dev/null | jq -r '.terraform_version // "unknown"'))"
else
  log_fail "Terraform CLI not found in PATH."
fi

if terraform validate &>/dev/null; then
  log_pass "Terraform configuration is syntactically valid (terraform validate)."
else
  log_fail "Terraform validation failed. Check syntax and required variables."
fi

# 2. State Check
if [ -f "terraform.tfstate" ]; then
  log_pass "terraform.tfstate file exists."
  
  # 3. Resource Output Verification
  VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
  if [ -n "$VPC_ID" ] && [[ "$VPC_ID" =~ ^vpc- ]]; then
    log_pass "VPC created successfully with ID: $VPC_ID"
  else
    log_fail "VPC ID not found or invalid in Terraform outputs."
  fi

  PUB_COUNT=$(terraform output -json public_subnet_ids 2>/dev/null | jq '. | length' 2>/dev/null || echo 0)
  if [ "$PUB_COUNT" -eq 2 ]; then
    log_pass "Public subnets verified: 2 subnets provisioned across Multi-AZ."
  else
    log_fail "Public subnets count mismatch: expected 2, found $PUB_COUNT."
  fi

  PRIV_COUNT=$(terraform output -json private_subnet_ids 2>/dev/null | jq '. | length' 2>/dev/null || echo 0)
  if [ "$PRIV_COUNT" -eq 2 ]; then
    log_pass "Private subnets verified: 2 subnets provisioned across Multi-AZ."
  else
    log_fail "Private subnets count mismatch: expected 2, found $PRIV_COUNT."
  fi

  NAT_EIP=$(terraform output -raw nat_gateway_public_ip 2>/dev/null || echo "")
  if [ -n "$NAT_EIP" ]; then
    log_pass "NAT Gateway Elastic IP allocated: $NAT_EIP"
  else
    log_fail "NAT Gateway Elastic IP missing."
  fi

  BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
  if [ -n "$BASTION_IP" ]; then
    log_pass "Bastion Jump Host deployed with Public IP: $BASTION_IP"
  else
    log_fail "Bastion Public IP missing."
  fi

  PRIV_IP=$(terraform output -raw private_app_ip 2>/dev/null || echo "")
  if [ -n "$PRIV_IP" ] && [[ "$PRIV_IP" =~ ^10\.0\.11\. ]]; then
    log_pass "Private App instance deployed with Isolated IP: $PRIV_IP"
  else
    log_fail "Private instance IP missing or not in 10.0.11.0/24 CIDR."
  fi

  # 4. Live Reachability Test (Optional if credentials and key exist)
  if [ -f "lab_key.pem" ] && [ -n "$BASTION_IP" ]; then
    echo "Testing Bastion SSH Port 22 connectivity..."
    if nc -z -w 5 "$BASTION_IP" 22 2>/dev/null; then
      log_pass "Bastion Host SSH port 22 is reachable from the internet."
    else
      echo "  (Note: SSH port unreachable or security group restricted - check allowed_ssh_cidr)"
    fi
  fi

else
  echo "  (terraform.tfstate not found locally. Run 'terraform apply' first to test live state.)"
fi

echo "----------------------------------------------------------"
echo "  SUMMARY: PASS=$PASS | FAIL=$FAIL"
echo "=========================================================="

if [ "$FAIL" -eq 0 ]; then
  echo -e "\033[32m>>> LAB-TF-08 VALIDATION SUCCESSFUL! <<<\033[0m"
  exit 0
else
  echo -e "\033[31m>>> LAB-TF-08 VALIDATION HAS WARNINGS/FAILURES! <<<\033[0m"
  exit 1
fi
