#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-JEN-02: Plugins manifest..."
test -f plugins.txt
echo "[PASS] Plugins list is valid."
