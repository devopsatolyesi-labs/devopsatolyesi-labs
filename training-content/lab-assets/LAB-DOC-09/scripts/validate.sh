#!/usr/bin/env bash
set -euo pipefail

echo "==> Validating LAB-DOC-09: User-Defined Docker Networks & DNS..."

NET_NAME="custom-app-net"
if ! docker network inspect "$NET_NAME" >/dev/null 2>&1; then
    docker network create "$NET_NAME" >/dev/null
fi

docker rm -f backend-service frontend-service 2>/dev/null || true

# Start backend container
docker run -d --name backend-service --network "$NET_NAME" nginx:alpine >/dev/null

# Build and run frontend container
docker build -t lab-doc-09-frontend:v1 . >/dev/null
docker run -d --name frontend-service --network "$NET_NAME" -p 8080:8080 \
    -e BACKEND_HOST="backend-service" -e BACKEND_PORT="80" lab-doc-09-frontend:v1 >/dev/null

sleep 2

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")

# Cleanup temporary containers created during validation test
docker rm -f backend-service frontend-service >/dev/null 2>&1 || true

if [ "$HTTP_CODE" = "200" ]; then
    echo "[PASS] LAB-DOC-09 Inter-container DNS communication verified (HTTP 200)."
    exit 0
else
    echo "[FAIL] LAB-DOC-09 Expected HTTP 200, got $HTTP_CODE" >&2
    exit 1
fi
