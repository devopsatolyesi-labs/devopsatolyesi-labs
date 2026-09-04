#!/usr/bin/env bash
set -euo pipefail

echo "==> [1/2] Docker İmajı Geri Yükleniyor (load)..."
docker load < alpine-backup.tar.gz

echo "==> [2/2] Docker Volume Geri Yükleniyor..."
docker volume create restored-app-data >/dev/null
docker run --rm   -v restored-app-data:/data   -v "$(pwd)":/backup:ro   alpine:3.21 tar -xzf /backup/volume-backup.tar.gz -C /data

echo "==> Doğrulama: Geri yüklenen veri:"
docker run --rm -v restored-app-data:/data alpine:3.21 cat /data/backup-test.txt
