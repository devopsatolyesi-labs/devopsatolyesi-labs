#!/usr/bin/env bash
# ==============================================================================
# Script: install-terraform.sh
# Purpose: Installs HashiCorp Terraform 1.16.x via official HashiCorp repository
# Upstream Pin: Terraform 1.16.0 (2026 Stable Release)
# ==============================================================================
set -euo pipefail

echo "==> [1/4] Setting up HashiCorp GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/hashicorp-archive-keyring.gpg ]; then
  wget -O- https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
fi

echo "==> [2/4] Adding HashiCorp official repository..."
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt-get update -y

echo "==> [3/4] Installing Terraform..."
sudo apt-get install -y terraform

echo "==> [4/4] Verifying Terraform installation..."
terraform version

echo "==> Running Terraform smoke test..."
TEMP_TF_DIR=$(mktemp -d)
cat <<'EOF' > "${TEMP_TF_DIR}/main.tf"
terraform {
  required_version = ">= 1.5.0"
}
output "smoke_test" {
  value = "TERRAFORM_OK"
}
EOF
(cd "${TEMP_TF_DIR}" && terraform init -no-color && terraform validate -no-color)
rm -rf "${TEMP_TF_DIR}"
echo "==> Terraform 1.16.x installed and smoke test passed successfully."
