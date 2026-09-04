# LAB-DOC-08 — Modern React / Statik Frontend Uygulamasını Nginx ile Dağıtma

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-08.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-08.zip && cd LAB-DOC-08`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-08
cd ~/labs/LAB-DOC-08
```

### `starter/Dockerfile`

```bash
mkdir -p "$(dirname -- starter/Dockerfile)"
cat > starter/Dockerfile <<'LAB_FILE_EOF_1'
# TODO: Aşama 1: Node.js Builder
# FROM node:20-alpine AS builder

# TODO: Aşama 2: Nginx Runtime
# FROM nginx:alpine
LAB_FILE_EOF_1
```

### `starter/index.html`

```bash
mkdir -p "$(dirname -- starter/index.html)"
cat > starter/index.html <<'LAB_FILE_EOF_2'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>DevOps Atölyesi Frontend</title>
</head>
<body>
    <h1>Modern Frontend Nginx Container</h1>
</body>
</html>
LAB_FILE_EOF_2
```

### `starter/nginx.conf`

```bash
mkdir -p "$(dirname -- starter/nginx.conf)"
cat > starter/nginx.conf <<'LAB_FILE_EOF_3'
events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # Single Page Application (SPA) Routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Statik dosyalar için önbellekleme
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
LAB_FILE_EOF_3
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "[BİLGİ] LAB-DOC-08 temizlendi."
LAB_FILE_EOF_4
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_5'
#!/usr/bin/env bash
set -euo pipefail
cp -a starter/. .
echo "[BİLGİ] LAB-DOC-08 sıfırlandı."
LAB_FILE_EOF_5
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_6'
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
LAB_FILE_EOF_6
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

Bu labın amacı, modern **React / Vue / Statik Web** uygulamalarını derleyip (Build) üretimde hafif ve yüksek performanslı **Nginx** web sunucusu üzerinde barındırmak için gereken **Multi-Stage Build**, **SPA Yönlendirmesi (`try_files`)**, **Gzip Sıkıştırması** ve **Önbellekleme (Caching)** tekniklerini uygulamalı olarak öğrenmektir.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ortamınızın hazır olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-08
cd ~/labs/LAB-DOC-08
```

ZIP indirdiyseniz `unzip LAB-DOC-08.zip && cd LAB-DOC-08` komutunu çalıştırın.

---

### Adım 2: SPA Uyumlu nginx.conf Yapılandırması

React Router gibi istemci taraflı yönlendiricilerin 404 vermemesi için `try_files $uri $uri/ /index.html;` kuralını içeren `nginx.conf` dosyasını oluşturun:

```bash
cat <<'EOF' > nginx.conf
events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # Single Page Application (SPA) Fallback
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Statik Varlıklar için Önbellekleme
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
```

---

### Adım 3: Multi-Stage Dockerfile ile İmajı Derleyin

```bash
cat <<'EOF' > Dockerfile
FROM node:20-alpine AS builder
WORKDIR /build

COPY index.html ./
RUN mkdir -p dist && cp index.html dist/

FROM nginx:alpine
WORKDIR /usr/share/nginx/html

RUN rm -rf ./*
COPY --from=builder /build/dist .
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

docker build -t lab-doc-08-frontend:latest .
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: React veya Vue SPA uygulamalarında Nginx üzerinde `try_files $uri $uri/ /index.html;` kuralı yazılmazsa kullanıcı sayfayı yenilediğinde (F5) neden 404 hatası alır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        SPA uygulamalarında yönlendirme (routing - örn: `/dashboard`, `/profile`) tarayıcıda JavaScript tarafından yönetilir; sunucu diskinde gerçekten `/dashboard/index.html` diye bir dosya yoktur. `try_files` olmadan kullanıcı doğrudan bir alt sayfayı açtığında Nginx o dosyayı arar ve bulamayınca 404 döner. Bu kural dosya bulunamadığında tüm istekleri `index.html`'e yönlendirerek JavaScript'in rotayı devralmasını sağlar.

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

Bu lab, [s3-landing-page](https://github.com/hakanbayraktar/s3-landing-page) açık kaynak projesindeki modern web dağıtım standartlarından uyarlanmıştır.
