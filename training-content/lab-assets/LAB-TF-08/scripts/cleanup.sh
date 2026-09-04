#!/usr/bin/env bash
# ==============================================================================
# Script: cleanup.sh
# Purpose: Safe cleanup of all AWS infrastructure to avoid incurring cloud costs
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "    AWS INFRASTRUCTURE COST-SAVING CLEANUP (LAB-TF-08)    "
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${LAB_DIR}/solution" 2>/dev/null || cd "${LAB_DIR}"

if [ -f "terraform.tfstate" ]; then
  echo "==> Running 'terraform destroy' to release NAT Gateway, EIP and EC2 instances..."
  terraform destroy -auto-approve
  echo "==> Removing generated private key file..."
  rm -f lab_key.pem
  echo "==> All AWS cloud resources have been successfully destroyed. Zero ongoing costs."
else
  echo "==> No active terraform.tfstate found. Nothing to destroy."
fi
