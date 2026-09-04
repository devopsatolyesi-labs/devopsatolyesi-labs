#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-10] Doğrulama Başlatılıyor: Docker Backup & Restore..."

if [[ ! -f backup.sh || ! -f restore.sh ]]; then
  echo "[HATA] backup.sh veya restore.sh bulunamadı! Lütfen ~/labs/LAB-DOC-10 dizininde çalıştırın." >&2
  exit 1
fi

chmod +x backup.sh restore.sh

echo "[1/3] backup.sh çalıştırılıyor..."
bash backup.sh >/dev/null 2>&1

if [[ ! -f alpine-backup.tar.gz || ! -f volume-backup.tar.gz ]]; then
  echo "[HATA] Beklenen yedek dosyaları (alpine-backup.tar.gz, volume-backup.tar.gz) üretilemedi!" >&2
  exit 1
fi

echo "[2/3] restore.sh çalıştırılıyor..."
bash restore.sh >/dev/null 2>&1

echo "[3/3] Geri yüklenen verinin doğruluğu kontrol ediliyor..."
output=$(docker run --rm -v restored-app-data:/data alpine:3.21 cat /data/backup-test.txt 2>/dev/null || true)

if [[ "$output" == *"DevOps Atolyesi"* ]]; then
  echo "[PASS] Docker İmaj ve Volume Backup/Restore doğrulaması eksiksiz geçti!"
  exit 0
else
  echo "[FAIL] Geri yüklenen volume verisi doğrulanamadı. Çıktı: '$output'" >&2
  exit 1
fi
