#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-LNX-01: Linux Preflight..."
bash preflight_check.sh >/dev/null
echo "[PASS] LAB-LNX-01 Preflight check executed with exit code 0."
