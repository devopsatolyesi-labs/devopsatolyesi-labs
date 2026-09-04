#!/usr/bin/env bash
set -euo pipefail

echo "==> [1/3] Docker İmajı Yedekleniyor (save + gzip)..."
docker pull alpine:3.21
docker save alpine:3.21 | gzip > alpine-backup.tar.gz

echo "==> [2/3] Test Volume ve Veri Hazırlanıyor..."
docker volume create test-app-data >/dev/null
docker run --rm -v test-app-data:/data alpine:3.21 sh -c 'echo "DevOps Atolyesi Backup Test $(date)" > /data/backup-test.txt'

echo "==> [3/3] Docker Volume Yedekleniyor (Temporary Container)..."
docker run --rm   -v test-app-data:/data:ro   -v "$(pwd)":/backup   alpine:3.21 tar -czf /backup/volume-backup.tar.gz -C /data .

echo "==> [BAŞARILI] İmaj ve Volume yedekleri başarıyla alındı!"
