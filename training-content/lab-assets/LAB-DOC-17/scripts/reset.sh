#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-10] Sıfırlanıyor..."
docker volume rm -f test-app-data restored-app-data 2>/dev/null || true
rm -f alpine-backup.tar.gz volume-backup.tar.gz 2>/dev/null || true
cp -a starter/. .
echo "[BİLGİ] LAB-DOC-10 başlangıç durumuna sıfırlandı."
