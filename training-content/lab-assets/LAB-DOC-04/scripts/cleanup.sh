#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-04] Temizleniyor..."
docker stop test-doc-04 2>/dev/null || true
docker rm -f test-doc-04 2>/dev/null || true
docker rmi -f lab-doc-04-hardened:latest 2>/dev/null || true
echo "[BİLGİ] LAB-DOC-04 kaynakları temizlendi."
