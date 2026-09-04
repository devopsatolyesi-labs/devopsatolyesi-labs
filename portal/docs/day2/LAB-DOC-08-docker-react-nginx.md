# LAB-DOC-08 — Modern React / Statik Frontend Uygulamasını Nginx ile Dağıtma

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `docker` | `80` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-08.zip)](/downloads/LAB-DOC-08.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


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
