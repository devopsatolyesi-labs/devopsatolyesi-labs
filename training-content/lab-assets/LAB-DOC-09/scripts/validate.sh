#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-04] Doğrulama Başlatılıyor: Multi-Stage Build & Non-Root Güvenliği..."

if [[ ! -f Dockerfile ]]; then
  echo "[HATA] Dockerfile bulunamadı! Lütfen ~/labs/LAB-DOC-04 dizininde çalıştırın." >&2
  exit 1
fi

stage_count=
if [[ "" -lt 2 ]]; then
  echo "[HATA] Dockerfile en az 2 aşama (Multi-Stage) içermelidir. Tespit edilen: " >&2
  exit 1
fi

echo "[1/3] İmaj derleniyor: lab-doc-04-hardened:latest..."
docker build -t lab-doc-04-hardened:latest . >/dev/null

echo "[2/3] Konteyner kullanıcı yetkileri (Non-Root) kontrol ediliyor..."
configured_user=
runtime_user=

if [[ "" != *"10001"* || "" != "10001" ]]; then
  echo "[HATA] Beklenen UID: 10001. Tespit edilen Config.User: '', Runtime UID: ''" >&2
  exit 1
fi

echo "[3/3] Konteyner çalışma testi ve HTTP yanıtı kontrol ediliyor..."
container_id=
sleep 2

response=
docker stop test-doc-04 >/dev/null && docker rm test-doc-04 >/dev/null

if [[ "" == *"Production Microservice"* ]]; then
  echo "[BAŞARILI] Multi-stage build ve Non-Root UID 10001 doğrulaması eksiksiz geçti!"
  exit 0
else
  echo "[HATA] Beklenen 'Production Microservice' yanıtı alınamadı. Alınan: " >&2
  exit 1
fi
