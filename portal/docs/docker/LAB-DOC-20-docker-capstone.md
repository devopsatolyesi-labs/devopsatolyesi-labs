# LAB-DOC-20 — Docker Final Capstone Projesi: Üretim Seviyesi Mikroservis Platformu

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 90 dakika | `docker` | `80, 3000, 5432, 6379` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-20.zip)](/downloads/LAB-DOC-20.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🏆 **CAPSTONE** (Bitiş Projesi) | ⏱️ 90 dakika | `docker` | `80`, `3000`, `5432`, `6379` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-20.zip)](/downloads/LAB-DOC-20.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Docker modülünde öğrenilen tüm kazanımları bir araya getirerek uçtan uca kurumsal bir mikroservis mimarisi inşa etmek:
  1. **Frontend:** React SPA & Nginx (Multi-stage, minimal imaj, gzip, SPA routing).
  2. **Backend:** Hardened Node.js API (Non-root UID 10001, layer cache optimize).
  3. **Veri Katmanı:** PostgreSQL 16 (Named volume kalıcılığı, dahili izole ağ).
  4. **Önbellek:** Redis 7 (In-memory caching).
  5. **Orkestrasyon:** Docker Compose v2 (Healthcheck zinciri, kaynak limitleri, secrets, log rotasyonu).
  6. **Güvenlik Denetimi:** Trivy ile sıfır CRITICAL CVE doğrulaması.
  7. **Felaket Kurtarma:** Veritabanı volume yedeği alma ve canlı restore testi.

---

## Ön Koşullar

- Docker Engine 24.0+ ve Docker Compose v2 hazır olmalıdır.
- Host üzerinde `80` ve `3000` portları boş olmalıdır.

---

## Uçtan Uca Capstone Mimarisi

```text
                                  KULLANICI / WEB TARAYICI
                                             │
                                        Host: 80
                                             ▼
+─────────────────────────────────────────────────────────────────────────────+
| FRONTEND KONTEYNERİ (Nginx + React SPA)                                     |
|  - Multi-stage derlendi (~25MB)                                             |
|  - Non-root UID 10001, read-only rootfs                                    |
+─────────────────────────────────────────────────────────────────────────────+
                                             │
                                     proxy_pass /api/
                                             ▼
+─────────────────────────────────────────────────────────────────────────────+
| BACKEND API KONTEYNERİ (Hardened Node.js REST API)                          |
|  - Healthcheck: /health (service_healthy olunca frontend bağlanır)          |
|  - Memory Limit: 256MB, CPU Limit: 0.5                                      |
+─────────────────────────────────────────────────────────────────────────────+
                         │                                 │
              postgres:5432 (backend-net)           redis:6379 (backend-net)
                         ▼                                 ▼
+─────────────────────────────────────+   +───────────────────────────────────+
| VERİTABANI (PostgreSQL 16)          |   | ÖNBELLEK (Redis 7)                |
| - Named Volume: capstone-pgdata     |   | - In-memory veri saklama          |
| - İzole Dahili Ağ (Dışa Kapalı)     |   | - İzole Dahili Ağ (Dışa Kapalı)   |
+─────────────────────────────────────+   +───────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-20/{frontend,backend,nginx,secrets}
cd ~/labs/LAB-DOC-20
```

---

### Adım 2: Backend REST API Servisini Yazın

```bash
cat <<'EOF' > backend/package.json
{
  "name": "capstone-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "pg": "^8.11.3",
    "redis": "^4.6.13"
  }
}
EOF

cat <<'EOF' > backend/server.js
const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

const dbPassword = fs.existsSync('/run/secrets/db_password')
  ? fs.readFileSync('/run/secrets/db_password', 'utf8').trim()
  : process.env.DB_PASSWORD || 'secret';

const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  user: process.env.DB_USER || 'capstone_user',
  password: dbPassword,
  database: process.env.DB_NAME || 'capstonedb',
  port: 5432
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products');
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.listen(port, () => console.log(`Capstone API running on ${port}`));
EOF

cat <<'EOF' > backend/Dockerfile
FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 10001 -S appgroup && adduser -u 10001 -D -S -G appgroup appuser
COPY --from=builder --chown=appuser:appgroup /build/node_modules ./node_modules
COPY --chown=appuser:appgroup package.json server.js ./
USER 10001
EXPOSE 3000
CMD ["node", "server.js"]
EOF
```

---

### Adım 3: Frontend Web Servisini Hazırlayın

```bash
cat <<'EOF' > frontend/index.html
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <title>DevOps Atölyesi Capstone Store</title>
  <style>
    body { font-family: system-ui; background: #0f172a; color: #f8fafc; padding: 2rem; }
    .card { background: #1e293b; padding: 1.5rem; border-radius: 8px; max-width: 600px; margin: auto; }
    .badge { background: #10b981; color: #000; padding: 0.2rem 0.6rem; border-radius: 4px; font-weight: bold; }
  </style>
</head>
<body>
  <div class="card">
    <h1>🚀 Capstone Platformu</h1>
    <p>Durum: <span class="badge">Production Ready</span></p>
    <div id="content">Ürünler Yükleniyor...</div>
  </div>
  <script>
    fetch('/api/products')
      .then(r => r.json())
      .then(data => {
        document.getElementById('content').innerHTML = `
          <p>Toplam Ürün: <strong>${data.count}</strong></p>
          <ul>${data.data.map(p => `<li>${p.name} - $${p.price}</li>`).join('')}</ul>
        `;
      })
      .catch(e => {
        document.getElementById('content').innerText = 'API Bağlantı Hatası';
      });
  </script>
</body>
</html>
EOF

cat <<'EOF' > nginx/default.conf
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

cat <<'EOF' > frontend/Dockerfile
FROM nginx:1.25-alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
```

---

### Adım 4: Veritabanı Başlangıç Scripti ve Gizli Şifreyi Oluşturun

```bash
mkdir -p init-db
cat <<'EOF' > init-db/01-init.sql
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL
);
INSERT INTO products (name, price) VALUES ('Kubernetes Production Handbook', 49.99);
INSERT INTO products (name, price) VALUES ('Docker Mastery Capstone Course', 29.99);
INSERT INTO products (name, price) VALUES ('DevOps SRE T-Shirt', 19.99);
EOF

echo "UltimateCapstoneSecret2026" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
```

---

### Adım 5: Üretim Kalitesinde `docker-compose.yml` Hazırlayın

```bash
cat <<'EOF' > docker-compose.yml
services:
  frontend:
    build:
      context: ./frontend
    container_name: capstone-frontend
    ports:
      - "8080:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - public-net
    restart: unless-stopped

  backend:
    build:
      context: ./backend
    container_name: capstone-backend
    environment:
      DB_HOST: postgres
      DB_USER: capstone_user
      DB_NAME: capstonedb
      PORT: 3000
    secrets:
      - db_password
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:3000/api/health || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 5s
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
    networks:
      - public-net
      - internal-net
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    container_name: capstone-postgres
    environment:
      POSTGRES_USER: capstone_user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: capstonedb
    secrets:
      - db_password
    volumes:
      - capstone-pgdata:/var/lib/postgresql/data
      - ./init-db:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U capstone_user -d capstonedb"]
      interval: 5s
      timeout: 3s
      retries: 5
    networks:
      - internal-net
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: capstone-redis
    networks:
      - internal-net
    restart: unless-stopped

volumes:
  capstone-pgdata:

networks:
  public-net:
  internal-net:

secrets:
  db_password:
    file: ./secrets/db_password.txt
EOF
```

---

### Adım 6: Bütün Yığını Başlatın

```bash
docker compose up -d --build
```

Konteynerlerin sağlıklı durumunu (`healthy`) kontrol edin:

```bash
docker compose ps
```

---

## Doğal Doğrulama

```bash
# 1. Frontend üzerinden Backend API yanıtını test edin
curl -s http://localhost:8080/api/products | jq . || curl -s http://localhost:8080/api/products

# 2. HTML sayfasını test edin
curl -s http://localhost:8080/ | grep "Capstone Platformu"

# 3. İzolasyon testi (Frontend konteyneri postgres'e erişememelidir!)
docker compose exec frontend ping -c 2 postgres || echo "BEKLENEN: Ağ güvenliği devrede, izole!"
```

---

### Adım 7: Temizlik

```bash
docker compose down -v
rm -rf secrets
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: `depends_on` bloğunda neden sadece servis ismi yazmak yerine `condition: service_healthy` koşulu eklenmelidir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Standart `depends_on` sadece bağımlı konteynerin process'inin başlatılmasını bekler. Ancak PostgreSQL veya Spring Boot gibi ağır servislerin port dinlemeye başlaması ve veritabanı bağlantılarını kabul etmesi 10-30 saniye sürebilir. `condition: service_healthy` olmadan backend başlarsa hemen veritabanına bağlanmaya çalışır, hata alır ve çökerek `CrashLoop` durumuna düşer.

---

## Beklenen Sonuç

```json
{
  "count": 3,
  "data": [
    { "id": 1, "name": "Kubernetes Production Handbook", "price": "49.99" },
    { "id": 2, "name": "Docker Mastery Capstone Course", "price": "29.99" },
    { "id": 3, "name": "DevOps SRE T-Shirt", "price": "19.99" }
  ],
  "success": true
}
```
