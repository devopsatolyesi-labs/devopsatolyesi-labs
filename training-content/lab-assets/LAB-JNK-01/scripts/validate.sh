#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-JNK-01: Declarative Pipeline..."
if [ -f Jenkinsfile ] && grep -q "pipeline {" Jenkinsfile && grep -q "stage('Unit Tests')" Jenkinsfile; then
    echo "[PASS] LAB-JNK-01 Declarative Jenkinsfile verified."
    exit 0
else
    echo "[FAIL] LAB-JNK-01 Incomplete Declarative Jenkinsfile."
    exit 1
fi
