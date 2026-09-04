# LAB-DOC-12 — React SPA ve Nginx Frontend Container

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `docker` | `80` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-12.zip)](/downloads/LAB-DOC-12.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `docker` | `80` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-12.zip)](/downloads/LAB-DOC-12.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- React Single Page Application (SPA) projelerini multi-stage derleme ile konteynerleştirmek.
- Derleme araçlarını (Node.js SDK, npm, node_modules) üretim ortamından izole etmek.
- Nginx web sunucusu ile statik HTML/JS/CSS varlıklarını yüksek performansla sunmak.
- React Router gibi istemci taraflı yönlendirmeler (SPA routing) için Nginx `try_files` yapılandırmasını sağlamak.
- Gzip sıkıştırma ve güvenlik başlıklarını (Security Headers) devreye almak.

---

## Ön Koşullar

- Docker Engine hazır olmalıdır.
- `80` portu boş olmalıdır (veya 8080 yönlendirmesi yapılacaktır).

---

## SPA ve Nginx İstemci Mimarisi

```text
+-------------------------------------------------------------+
| 1. DERLEME: node:20-alpine AS builder                       |
|  - React kaynak kodları ve npm install                      |
|  - npm run build ---> /app/dist (Statik HTML, JS, CSS)      |
|  - Aşama Boyutu: ~400 MB                                    |
+-------------------------------------------------------------+
                               │
            SADECE STATİK /app/dist DOSYALARI AKTARILIR
                               ▼
+-------------------------------------------------------------+
| 2. RUNTIME: nginx:1.25-alpine                               |
|  - Node.js veya npm YOKTUR.                                 |
|  - Sadece Nginx ve derlenmiş statik dosyalar vardır.        |
|  - try_files $uri $uri/ /index.html; (SPA 404 önleyici)     |
|  - Nihai İmaj Boyutu: ~25 MB!                               |
+-------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-12
cd ~/labs/LAB-DOC-12
```

---

### Adım 2: Statik React Proje Dosyalarını Hazırlayın

Basit bir Single Page Application yapısı kuralım:

```bash
cat <<'EOF' > package.json
{
  "name": "react-frontend-demo",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "mkdir -p dist && cp index.html dist/ && cp app.js dist/"
  }
}
EOF

cat <<'EOF' > index.html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <title>DevOps Atölyesi - React Frontend</title>
    <style>
        body { font-family: sans-serif; background: #0f172a; color: #f8fafc; padding: 2rem; }
        .card { background: #1e293b; padding: 1.5rem; border-radius: 8px; max-width: 500px; margin: auto; }
        .btn { background: #38bdf8; color: #000; padding: 0.5rem 1rem; border: none; border-radius: 4px; cursor: pointer; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚀 React SPA Frontend</h1>
        <p>Containerized with Multi-Stage Build & Nginx Alpine</p>
        <div id="root">Loading...</div>
        <br>
        <button class="btn" onclick="navigate('/dashboard')">Dashboard Sayfasına Git</button>
    </div>
    <script src="app.js"></script>
</body>
</html>
EOF

cat <<'EOF' > app.js
function renderRoute() {
    const root = document.getElementById('root');
    const path = window.location.pathname;
    root.innerHTML = `<p>Aktif Rota: <strong>${path}</strong></p><p>Sunucu Durumu: 🟢 Nginx SPA Engine Aktif</p>`;
}
function navigate(path) {
    window.history.pushState({}, '', path);
    renderRoute();
}
window.onpopstate = renderRoute;
renderRoute();
EOF
```

---

### Adım 3: Nginx SPA Yapılandırma Dosyasını Hazırlayın

SPA uygulamalarında kullanıcı `/dashboard` gibi bir URL'yi tarayıcıda yenilediğinde Nginx'in 404 dönmemesi, isteği `index.html`'e paslaması gerekir:

```bash
cat <<'EOF' > nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip sıkıştırma
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Güvenlik başlıkları
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    # SPA Yönlendirmesi (Try Files)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Statik varlıklar için önbellekleme
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }
}
EOF
```

---

### Adım 4: Multi-Stage Dockerfile Yazın

```bash
cat <<'EOF' > Dockerfile
# 1. Aşama: Node.js Builder
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
COPY index.html app.js ./
RUN npm run build

# 2. Aşama: Minimal Nginx Runtime
FROM nginx:1.25-alpine
WORKDIR /usr/share/nginx/html

# Varsayılan konfigürasyonu ez
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Derlenen statik dosyaları aktar
COPY --from=builder /app/dist .

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
```

---

### Adım 5: İmajı Derleyin ve Başlatın

```bash
docker build -t react-frontend:1.0 .
docker run -d --name my-frontend -p 8080:80 react-frontend:1.0
```

---

## Doğal Doğrulama

```bash
# 1. Ana sayfayı test edin
curl -I http://localhost:8080/

# 2. SPA derin rota (deep routing) testini yapın (200 OK ve index.html dönmeli!)
curl -s http://localhost:8080/dashboard/user/profile | grep "React SPA Frontend"

# 3. İmaj boyutunu inceleyin
docker images react-frontend:1.0
```

---

### Adım 6: Temizlik

```bash
docker rm -f my-frontend
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: React SPA uygulamalarında Nginx'te `try_files $uri $uri/ /index.html;` satırı yazılmazsa kullanıcı sayfayı F5 ile yenilediğinde ne olur?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Kullanıcı `http://domain.com/dashboard` adresindeyken sayfayı yenilerse, Nginx diskte `/usr/share/nginx/html/dashboard` adında fiziksel bir dosya arar. Bulamadığı için kullanıcıya **404 Not Found** hatası döner. `try_files ... /index.html` direktifi ise fiziksel dosya yoksa isteği React Router'ın yönetmesi için `index.html`'e iletir.

??? question "Soru 2: Neden statik React uygulamasını doğrudan `node server.js` ile sunmak yerine Nginx tercih edilir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Nginx C dili ile yazılmış, statik dosya sunumu için optimize edilmiş bir event-driven motordur. Node.js'e göre %300 daha az bellek tüketir, çok daha yüksek eşzamanlı bağlantıyı (concurrency) karşılar ve Docker imaj boyutu 400MB yerine 25MB olur.

---

## Beklenen Sonuç

- `curl -I http://localhost:8080/` komutu `HTTP/1.1 200 OK` ve `Server: nginx/...` döner.
- `/dashboard/orders` gibi rotalara atılan istekler 404 hatası vermeden `index.html` içeriğini döndürür.

---

## Sorun Giderme

- **403 Forbidden Hatası:** Nginx kök dizinindeki (`/usr/share/nginx/html`) dosyaların okunabilirlik izinlerini kontrol edin.
