#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-CAP-01: Capstone Pipeline..."
bash scripts/ci_pipeline_runner.sh
echo "[PASS] LAB-CAP-01 End-to-End pipeline runner validated."
