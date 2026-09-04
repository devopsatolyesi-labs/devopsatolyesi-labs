#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-08] Doğrulama Başlatılıyor: React / Static Frontend Nginx..."

if [[ ! -f Dockerfile || ! -f nginx.conf ]]; then
  echo "[HATA] Dockerfile veya nginx.conf bulunamadı! ~/labs/LAB-DOC-08 dizininde çalıştırın." >&2
  exit 1
fi

if ! grep -q 'try_files' nginx.conf; then
  echo "[HATA] nginx.conf dosyasında SPA desteği için 'try_files' yönlendirmesi bulunmalıdır." >&2
  exit 1
fi

echo "[PASS] React / Statik Frontend Nginx yapılandırması başarıyla doğrulandı!"
