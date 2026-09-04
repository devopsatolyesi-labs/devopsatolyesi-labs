#!/usr/bin/env bash
# ==============================================================================
# Script: reset.sh
# Purpose: Completely destroys AWS VPC resources and resets the workspace
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> [RESET] Destroying Terraform managed AWS resources for LAB-TF-08..."
cd "${LAB_DIR}/solution" 2>/dev/null || cd "${LAB_DIR}"

if [ -f "terraform.tfstate" ]; then
  terraform destroy -auto-approve || true
fi

echo "==> [RESET] Cleaning up local state and keys..."
rm -f terraform.tfstate* lab_key.pem .terraform.lock.hcl
rm -rf .terraform/

echo "==> [RESET] Re-initializing Terraform clean state..."
terraform init -backend=false || true

echo "==> [RESET] Workspace reset complete. You can now restart LAB-TF-08 from Step 1."
