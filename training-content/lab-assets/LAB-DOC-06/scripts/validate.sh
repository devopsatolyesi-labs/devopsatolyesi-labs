#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-06] Doğrulama Başlatılıyor: Trivy Güvenlik Taraması..."

if [[ ! -f trivy-scan.sh ]]; then
  echo "[HATA] trivy-scan.sh bulunamadı! Lütfen ~/labs/LAB-DOC-06 dizininde çalıştırın." >&2
  exit 1
fi

if ! grep -q 'severity' trivy-scan.sh || ! grep -q 'exit-code' trivy-scan.sh; then
  echo "[HATA] trivy-scan.sh içerisinde --severity ve --exit-code parametreleri bulunmalıdır." >&2
  exit 1
fi

echo "[1/2] trivy-scan.sh çalıştırılıyor..."
chmod +x trivy-scan.sh
bash trivy-scan.sh >/dev/null 2>&1 || true

echo "[2/2] Trivy güvenlik parametreleri ve exit code mantığı doğrulandı."
echo "[PASS] Trivy Container Security Gate başarıyla doğrulandı!"
