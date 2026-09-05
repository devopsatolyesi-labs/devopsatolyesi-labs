# LAB-DOC-13 — Docker Compose ile Çok Katmanlı Mimari

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 50 dakika | `docker` | `80, 3000, 5432` |

[LAB-DOC-13.zip](/downloads/LAB-DOC-13.zip)


---

## Amaç

- Çok konteynerli (multi-container) mimarileri tek bir `docker-compose.yml` bildirimi ile yönetmek.
- Üç katmanlı (Frontend Web + Backend API + PostgreSQL Veritabanı) yığını orkestre etmek.
- Servisler arası DNS çözümlemesi ve dahili ağ (internal network) izolasyonu kurmak.
- `depends_on` ve başlatma bağımlılıklarını yönetmek.
- Named volume ile veritabanı verilerini kalıcı hale getirmek.

---

## Ön Koşullar

- Docker Engine ve Docker Compose v2 hazır olmalıdır (`docker compose version`).
- `8080` portu boş olmalıdır.

---

## Çok Katmanlı Mimari Şeması

```text
                  İSTEMCİ / WEB TARAYICI
                            │
                       Host: 8080
                            ▼
+─────────────────────────────────────────────────────────────+
| FRONTEND SERVİSİ (web)                                      |
|  - Nginx Ters Proxy & Statik Web                            |
|  - frontend-net ağına bağlı                                 |
+─────────────────────────────────────────────────────────────+
                            │
               http://api:3000 (Dahili DNS)
                            ▼
+─────────────────────────────────────────────────────────────+
| BACKEND SERVİSİ (api)                                       |
|  - Node.js Express REST API                                 |
|  - Hem frontend-net hem backend-net ağına bağlı             |
+─────────────────────────────────────────────────────────────+
                            │
               postgres:5432 (Dahili DNS, Dışa Kapalı!)
                            ▼
+─────────────────────────────────────────────────────────────+
| VERİTABANI SERVİSİ (db)                                     |
|  - PostgreSQL 16 Alpine                                    |
|  - Sadece backend-net ağına bağlı (İzole!)                  |
|  - Named Volume: db-data                                    |
+─────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-13
cd ~/labs/LAB-DOC-13
```

---

### Adım 2: Backend API Servisini Hazırlayın

```bash
mkdir -p api
cat <<'EOF' > api/package.json
{
  "name": "compose-backend",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "express": "^4.19.2",
    "pg": "^8.11.3"
  }
}
EOF

cat <<'EOF' > api/index.js
const express = require('express');
const { Pool } = require('pg');
const app = express();

const pool = new Pool({
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'secret123',
  database: process.env.DB_NAME || 'shopdb',
  port: 5432
});

app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as time');
    res.json({ status: 'ok', db_connected: true, time: result.rows[0].time });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

app.listen(3000, () => console.log('API running on 3000'));
EOF

cat <<'EOF' > api/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY index.js .
USER node
EXPOSE 3000
CMD ["node", "index.js"]
EOF
```

---

### Adım 3: Frontend Nginx Servisini Hazırlayın

```bash
mkdir -p web
cat <<'EOF' > web/default.conf
server {
    listen 80;

    location / {
        return 200 '{"portal":"DevOps Shop","status":"online"}
';
        add_header Content-Type application/json;
    }

    location /api/ {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF
```

---

### Adım 4: `docker-compose.yml` Bildirimini Tanımlayın

```bash
cat <<'EOF' > docker-compose.yml
services:
  web:
    image: nginx:1.25-alpine
    container_name: shop-web
    ports:
      - "8080:80"
    volumes:
      - ./web/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - api
    networks:
      - frontend-net
    restart: unless-stopped

  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    container_name: shop-api
    environment:
      DB_HOST: db
      DB_USER: shop_user
      DB_PASSWORD: super_secret_password
      DB_NAME: shopdb
    depends_on:
      - db
    networks:
      - frontend-net
      - backend-net
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    container_name: shop-db
    environment:
      POSTGRES_USER: shop_user
      POSTGRES_PASSWORD: super_secret_password
      POSTGRES_DB: shopdb
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend-net
    restart: unless-stopped

volumes:
  db-data:

networks:
  frontend-net:
  backend-net:
EOF
```

---

### Adım 5: Yığını Başlatın ve Yönetin

Bütün yığını arka planda derleyin ve ayağa kaldırın:

```bash
docker compose up -d --build
```

Konteynerlerin durumunu kontrol edin:

```bash
docker compose ps
```

---

## Doğal Doğrulama

```bash
# 1. Frontend üzerinden Backend ve Veritabanı zincirleme bağlantısını test edin
curl -s http://localhost:8080/api/health | jq . || curl -s http://localhost:8080/api/health

# 2. Ağ izolasyonunu doğrulayın (Web konteyneri veritabanına erişememelidir!)
docker compose exec web ping -c 2 db || echo "BEKLENEN: Web servisi db servisine izole, erişemez!"

# 3. Logları inceleyin
docker compose logs api
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```json
{
  "db_connected": true,
  "status": "ok",
  "time": "2026-09-04T16:45:00.000Z"
}
```
