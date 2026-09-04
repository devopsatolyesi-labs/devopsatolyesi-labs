#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-10] Temizleniyor..."
docker volume rm -f test-app-data restored-app-data 2>/dev/null || true
rm -f alpine-backup.tar.gz volume-backup.tar.gz 2>/dev/null || true
echo "[BİLGİ] LAB-DOC-10 kaynakları temizlendi."
