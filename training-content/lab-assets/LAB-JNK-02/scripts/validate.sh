#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-JNK-02: DevSecOps Pipeline..."
if [ -f Jenkinsfile ] && grep -q "Trivy" Jenkinsfile && [ -f Dockerfile ]; then
    echo "[PASS] LAB-JNK-02 DevSecOps pipeline and Dockerfile verified."
    exit 0
else
    echo "[FAIL] LAB-JNK-02 Missing pipeline or Dockerfile."
    exit 1
fi
