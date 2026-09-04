# LAB-LNX-02 — Nginx Üzerinde Let's Encrypt SSL/TLS Kurulumu ve Otomatik Yenileme

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-LNX-02.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-LNX-02.zip && cd LAB-LNX-02`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-LNX-02
cd ~/labs/LAB-LNX-02
```

### `starter/certbot-setup.sh`

```bash
mkdir -p "$(dirname -- starter/certbot-setup.sh)"
cat > starter/certbot-setup.sh <<'LAB_FILE_EOF_1'
#!/usr/bin/env bash
set -euo pipefail

# TODO: Certbot ile test sertifikası üretin veya kendi kendine imzalı simülasyon sertifikası oluşturun
LAB_FILE_EOF_1
```

### `starter/nginx.conf`

```bash
mkdir -p "$(dirname -- starter/nginx.conf)"
cat > starter/nginx.conf <<'LAB_FILE_EOF_2'
events { worker_connections 1024; }

http {
    server {
        listen 80;
        server_name example.devopsatolyesi.local;

        # TODO: Let's Encrypt / Certbot ACME challenge dizinini tanımlayın
        # location /.well-known/acme-challenge/ {
        #     root /var/www/certbot;
        # }

        # TODO: Tüm HTTP trafiğini HTTPS'e yönlendirin (301 redirect)
        location / {
            return 200 "HTTP Insecure Server\n";
        }
    }
}
LAB_FILE_EOF_2
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
sudo rm -rf /etc/letsencrypt/live/example.devopsatolyesi.local 2>/dev/null || true
echo "[BİLGİ] LAB-LNX-02 temizlendi."
LAB_FILE_EOF_3
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
cp -a starter/. .
echo "[BİLGİ] LAB-LNX-02 sıfırlandı."
LAB_FILE_EOF_4
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_5'
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
LAB_FILE_EOF_5
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

Bu labın amacı, Linux ve web sunucusu ortamlarında güvenli HTTP iletişimi (HTTPS) sağlamak için **Nginx** üzerinde **Let's Encrypt SSL/TLS sertifikası** kurulumunu, HTTP'den HTTPS'e kalıcı yönlendirmeyi (`301 Redirect`) ve Certbot ile otomatik sertifika yenileme (Renewal) mekanizmasını uygulamalı olarak öğrenmektir.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Linux sunucunuzda Nginx veya Docker ortamının hazır olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

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

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Let's Encrypt sertifikalarının geçerlilik süresi neden 90 gündür ve yenileme otomasyonu nasıl kurulur?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        90 günlük kısa süre, çalınan sertifikaların zararını sınırlandırmak ve web yöneticilerini yenilemeyi zorunlu olarak otomatikleştirmeye teşvik etmek içindir. Linux'ta `systemd timer` veya `cron` ile günde iki kez `certbot renew --quiet --deploy-hook "systemctl reload nginx"` komutu çalıştırılarak otomatik yenilenir.

??? question "Soru 2: HTTP'den HTTPS'e yönlendirirken neden 302 yerine 301 HTTP durum kodu kullanılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `301 Moved Permanently` arama motorlarına ve tarayıcılara bu adresin kalıcı olarak HTTPS'e taşındığını bildirir. Tarayıcılar bu yanıtı önbelleğe alır ve sonraki ziyaretlerde doğrudan HTTPS portuna bağlanarak performansı artırır ve arama motoru (SEO) sıralamasını korur.

??? question "Soru 3: Nginx'te `ssl_protocols TLSv1.2 TLSv1.3;` satırı ile SSLv3 ve TLSv1.0/1.1 neden devre dışı bırakılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        SSLv3, TLS 1.0 ve TLS 1.1 protokolleri POODLE, BEAST ve Heartbleed gibi kritik şifreleme açıklarına karşı savunmasızdır. PCI-DSS ve güncel web güvenlik standartları yalnızca TLS 1.2 ve TLS 1.3 kullanımını zorunlu kılar.

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak ve Referanslar

Bu lab, [Step-by-Step Guide: Install Let’s Encrypt SSL on Nginx (Amazon Linux 2023 / Ubuntu) — Hakan Bayraktar](https://hbayraktar.medium.com/step-by-step-guide-install-lets-encrypt-ssl-on-nginx-amazon-linux-2023-91138089c5a9) makalesinden uyarlanmıştır.
