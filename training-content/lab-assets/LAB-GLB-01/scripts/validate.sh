#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-GLB-01: GitLab CI Pipeline..."
if [ -f .gitlab-ci.yml ] && grep -q "unit-tests:" .gitlab-ci.yml && [ -f app/package.json ]; then
    node app/test.js
    echo "[PASS] LAB-GLB-01 GitLab CI configuration verified."
    exit 0
else
    echo "[FAIL] LAB-GLB-01 GitLab CI config missing or invalid."
    exit 1
fi
