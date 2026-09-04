#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-JNK-01: Declarative Pipeline..."
if [[ ! -f Jenkinsfile ]] || ! grep -q "pipeline {" Jenkinsfile || ! grep -q "stage('Unit Tests')" Jenkinsfile; then
    echo "[FAIL] LAB-JNK-01 Incomplete Declarative Jenkinsfile."
    exit 1
fi
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install --quiet --disable-pip-version-check -r requirements.txt
mkdir -p reports
flake8 src/ --max-line-length=100
pytest --junitxml=reports/junit-report.xml --cov=src tests/
test -s reports/junit-report.xml
echo "[PASS] LAB-JNK-01 Declarative Jenkinsfile and Python tests verified."
