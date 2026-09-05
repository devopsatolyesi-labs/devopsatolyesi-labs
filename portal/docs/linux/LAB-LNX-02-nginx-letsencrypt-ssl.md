# LAB-LNX-02 — Nginx Üzerinde Let's Encrypt SSL/TLS Kurulumu ve Otomatik Yenileme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 40 dakika | `docker` | `80, 443` |

[LAB-LNX-02.zip](/downloads/LAB-LNX-02.zip)


## Amaç

Bu labın amacı, Linux ve web sunucusu ortamlarında güvenli HTTP iletişimi (HTTPS) sağlamak için **Nginx** üzerinde **Let's Encrypt SSL/TLS sertifikası** kurulumunu, HTTP'den HTTPS'e kalıcı yönlendirmeyi (`301 Redirect`) ve Certbot ile otomatik sertifika yenileme (Renewal) mekanizmasını uygulamalı olarak öğrenmektir.

---

## Ön Koşullar

**Not:** Bu labı uygulayabilmek için Linux sunucunuzda Nginx veya Docker ortamının hazır olması gerekir.
- Henüz kurulu değilse: [Docker Engine Kurulum Rehberi](/setup/docker-engine/) adımlarını izleyin.

Hızlı sistem ön kontrolü:

```bash
openssl version
which nginx || docker --version
```

---

## SSL/TLS ve ACME Çalışma Modeli

```text
[ İstemci ] ---(Port 80 HTTP)---> [ Nginx Server ] ---(301 Permanent Redirect)---> [ Port 443 HTTPS ]
                                         ^
                                         | (ACME HTTP-01 Challenge)
                                  [ Certbot Client ] <---> [ Let's Encrypt CA ]
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-LNX-02
cd ~/labs/LAB-LNX-02
```

ZIP indirdiyseniz `unzip LAB-LNX-02.zip && cd LAB-LNX-02` komutunu çalıştırın.

---

### Adım 2: SSL/TLS Sertifikalarını Hazırlayın

Certbot / Let's Encrypt sertifika yapısını oluşturun:

```bash
cat <<'EOF' > certbot-setup.sh
#!/usr/bin/env bash
set -euo pipefail

DOMAIN="example.devopsatolyesi.local"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"

sudo mkdir -p "$CERT_DIR"
sudo mkdir -p /var/www/certbot

# Simülasyon için güçlü RSA 2048-bit sertifika üretimi
sudo openssl req -x509 -nodes -days 90 -newkey rsa:2048   -keyout "$CERT_DIR/privkey.pem"   -out "$CERT_DIR/fullchain.pem"   -subj "/C=TR/ST=Istanbul/O=DevOpsAtolyesi/CN=$DOMAIN"

echo "==> Sertifika dizini: $CERT_DIR"
EOF

chmod +x certbot-setup.sh
./certbot-setup.sh
```

---

### Adım 3: Nginx SSL ve HTTPS Yönlendirme Yapılandırması

`nginx.conf` dosyasını oluşturun:

```bash
cat <<'EOF' > nginx.conf
events { worker_connections 1024; }

http {
    # 1. HTTP Sunucusu (Port 80): ACME Doğrulama ve HTTPS'e Yönlendirme
    server {
        listen 80;
        server_name example.devopsatolyesi.local;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # 2. HTTPS Sunucusu (Port 443): SSL Sonlandırma ve Güvenli Servis
    server {
        listen 443 ssl;
        server_name example.devopsatolyesi.local;

        ssl_certificate /etc/letsencrypt/live/example.devopsatolyesi.local/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.devopsatolyesi.local/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            default_type text/html;
            return 200 "<h1>HTTPS Secure Nginx with Let's Encrypt</h1>
";
        }
    }
}
EOF
```

---

### Adım 4: Yapılandırmayı Test Edin

```bash
# Nginx konteyneri ile test edin
docker run --rm -d --name nginx-ssl-test   -p 8080:80 -p 8443:443   -v "$(pwd)/nginx.conf":/etc/nginx/nginx.conf:ro   -v /etc/letsencrypt:/etc/letsencrypt:ro   nginx:alpine

# HTTP yönlendirmesini test edin (301 Moved Permanently)
curl -I http://localhost:8080/

# HTTPS bağlantısını test edin
curl -k https://localhost:8443/

docker rm -f nginx-ssl-test
```

---

## Doğal Doğrulama ve Beklenen Sonuç

`curl -I http://localhost:8080/` isteği HTTPS adresine yönlendiren bir `301` yanıtı, `curl -k https://localhost:8443/` isteği ise Nginx uygulama içeriğini döndürmelidir. Konteyner loglarında sertifika dosyası veya Nginx yapılandırma hatası bulunmamalıdır.
