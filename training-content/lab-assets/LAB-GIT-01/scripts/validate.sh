#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-GIT-01: Git Config Resolution..."
if grep -q '"auth": "JWT_OAUTH2"' app-config.json && grep -q '"port": 9090' app-config.json; then
    echo "[PASS] LAB-GIT-01 Conflict resolved with required parameters."
    exit 0
else
    echo "[FAIL] LAB-GIT-01 app-config.json missing expected configuration."
    exit 1
fi
