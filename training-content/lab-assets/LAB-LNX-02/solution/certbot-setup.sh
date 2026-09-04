#!/usr/bin/env bash
set -euo pipefail

DOMAIN="example.devopsatolyesi.local"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"

sudo mkdir -p "$CERT_DIR"
sudo mkdir -p /var/www/certbot

# Simülasyon için OpenSSL ile geçerli sertifika çifti üretimi
sudo openssl req -x509 -nodes -days 90 -newkey rsa:2048   -keyout "$CERT_DIR/privkey.pem"   -out "$CERT_DIR/fullchain.pem"   -subj "/C=TR/ST=Istanbul/O=DevOpsAtolyesi/CN=$DOMAIN"

echo "==> [BAŞARILI] Let's Encrypt simülasyon sertifikaları üretildi."
