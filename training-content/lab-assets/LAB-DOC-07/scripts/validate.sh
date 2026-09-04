#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-07] Doğrulama Başlatılıyor: Java Spring Boot Multi-Stage..."

if [[ ! -f Dockerfile ]]; then
  echo "[HATA] Dockerfile bulunamadı! ~/labs/LAB-DOC-07 dizininde çalıştırın." >&2
  exit 1
fi

stage_count=$(grep -Ec '^[[:space:]]*FROM[[:space:]]+' Dockerfile)
if [[ "$stage_count" -lt 2 ]]; then
  echo "[HATA] Dockerfile en az 2 aşama (Multi-Stage) içermelidir." >&2
  exit 1
fi

if ! grep -q 'MaxRAMPercentage' Dockerfile && ! grep -q 'UseContainerSupport' Dockerfile; then
  echo "[HATA] JVM container bellek optimizasyon bayrakları (MaxRAMPercentage veya UseContainerSupport) bulunmalıdır." >&2
  exit 1
fi

echo "[PASS] Java Spring Boot multi-stage build ve JVM optimizasyonu başarıyla doğrulandı!"
