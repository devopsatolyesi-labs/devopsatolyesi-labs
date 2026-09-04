#!/usr/bin/env bash
set -euo pipefail
python3 -m py_compile app.py
echo "[PASS] Python script is syntactically valid."
