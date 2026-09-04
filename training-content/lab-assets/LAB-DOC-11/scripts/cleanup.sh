#!/usr/bin/env bash
set -euo pipefail

docker rm -f spring-app 2>/dev/null || true
docker rmi -f spring-boot-demo:1.0.0 2>/dev/null || true
echo "[BİLGİ] LAB-DOC-07 ortamı başarıyla temizlendi."
