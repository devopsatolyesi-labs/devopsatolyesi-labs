#!/usr/bin/env bash
set -euo pipefail
test -f app/calculator.py
test -f tests/test_calculator.py
echo "[PASS] Calculator app and tests exist."
