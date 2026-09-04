#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-01: First Container..."
docker build -t devops-first-container:v1 . >/dev/null
docker run -d --name lab-doc-01-test -p 8080:8080 devops-first-container:v1 >/dev/null
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")
docker rm -f lab-doc-01-test >/dev/null 2>&1 || true
if [ "$HTTP_CODE" = "200" ]; then
    echo "[PASS] LAB-DOC-01 Container responds with HTTP 200"
    exit 0
else
    echo "[FAIL] LAB-DOC-01 Expected HTTP 200, got $HTTP_CODE"
    exit 1
fi
