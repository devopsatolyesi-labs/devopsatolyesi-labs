#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-LNX-03] Doğrulama Başlatılıyor: SSH Tunneling..."

if [[ ! -f tunnel-setup.sh ]]; then
  echo "[HATA] tunnel-setup.sh bulunamadı! ~/labs/LAB-LNX-03 dizininde çalıştırın." >&2
  exit 1
fi

if ! grep -q '\-L' tunnel-setup.sh || ! grep -q '3306' tunnel-setup.sh; then
  echo "[HATA] tunnel-setup.sh içinde -L bayrağı ve hedef MySQL portu (3306) bulunmalıdır." >&2
  exit 1
fi

echo "[PASS] SSH Tünelleme komutu ve port yönlendirme mantığı başarıyla doğrulandı!"
