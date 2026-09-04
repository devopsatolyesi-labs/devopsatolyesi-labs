#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-GHA-01] Doğrulama Başlatılıyor: GitHub Actions CI..."

if [[ ! -f .github/workflows/ci.yml ]]; then
  echo "[HATA] .github/workflows/ci.yml bulunamadı! ~/labs/LAB-GHA-01 dizininde çalıştırın." >&2
  exit 1
fi

if ! grep -q 'runs-on: ubuntu-latest' .github/workflows/ci.yml || ! grep -q 'actions/checkout' .github/workflows/ci.yml; then
  echo "[HATA] Workflow içinde 'runs-on: ubuntu-latest' ve 'actions/checkout' adımları bulunmalıdır." >&2
  exit 1
fi

echo "[PASS] GitHub Actions CI workflow dosyası ve adımları başarıyla doğrulandı!"
