#!/usr/bin/env bash
rm -rf .terraform .terraform.lock.hcl terraform.tfstate* 2>/dev/null || true
echo "Cleanup completed for LAB-TF-01."
