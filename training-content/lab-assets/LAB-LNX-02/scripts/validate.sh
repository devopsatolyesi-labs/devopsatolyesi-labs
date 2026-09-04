#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-LNX-02] Doğrulama Başlatılıyor: Nginx Let's Encrypt SSL/TLS..."

if [[ ! -f nginx.conf ]]; then
  echo "[HATA] nginx.conf dosyası bulunamadı! ~/labs/LAB-LNX-02 dizininde çalıştırın." >&2
  exit 1
fi

if ! grep -q '443 ssl' nginx.conf || ! grep -q 'return 301 https' nginx.conf; then
  echo "[HATA] nginx.conf içinde 443 ssl ve HTTPS yönlendirmesi (301) tanımlanmalıdır." >&2
  exit 1
fi

echo "[PASS] Nginx SSL/TLS konfigürasyonu ve HTTPS yönlendirmesi başarıyla doğrulandı!"
