#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-TF-01: Terraform configuration..."
terraform init -backend=false -input=false >/dev/null
terraform validate
echo "[PASS] Terraform configuration is valid."
