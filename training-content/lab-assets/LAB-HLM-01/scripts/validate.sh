#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-HLM-01: Helm Chart structure..."
helm lint .
echo "[PASS] Helm chart lint completed with zero errors."
