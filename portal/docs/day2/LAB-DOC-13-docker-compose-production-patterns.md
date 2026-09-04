# LAB-DOC-13 — Production-Ready Docker Compose Mimarisi ve Desenleri

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-13.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-13.zip && cd LAB-DOC-13`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-13
cd ~/labs/LAB-DOC-13
```

### `starter/.env.example`

```bash
mkdir -p "$(dirname -- starter/.env.example)"
cat > starter/.env.example <<'LAB_FILE_EOF_1'
ENVIRONMENT=production
GATEWAY_PORT=8080
POSTGRES_DB=order_db
POSTGRES_USER=order_user
POSTGRES_PASSWORD=training-only-password
REDIS_HOST=redis-broker
LAB_FILE_EOF_1
```

### `starter/app/Dockerfile`

```bash
mkdir -p "$(dirname -- starter/app/Dockerfile)"
cat > starter/app/Dockerfile <<'LAB_FILE_EOF_2'
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run as non-root user
RUN useradd -u 10001 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
LAB_FILE_EOF_2
```

### `starter/app/main.py`

```bash
mkdir -p "$(dirname -- starter/app/main.py)"
cat > starter/app/main.py <<'LAB_FILE_EOF_3'
import os
import psycopg2
import redis
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Enterprise Order API", version="1.0.0")

DB_HOST = os.getenv("DB_HOST", "postgres-db")
DB_NAME = os.getenv("DB_NAME", "order_db")
DB_USER = os.getenv("DB_USER", "order_user")
DB_PASS = os.getenv("DB_PASS", "order_secret_pass")
REDIS_HOST = os.getenv("REDIS_HOST", "redis-broker")

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        connect_timeout=3
    )

def get_redis_connection():
    return redis.Redis(host=REDIS_HOST, port=6379, socket_timeout=3)

@app.on_event("startup")
def init_tables():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                item_name VARCHAR(100) NOT NULL,
                quantity INT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Startup DB init error: {e}")

@app.get("/healthz")
def healthz():
    db_ok = False
    redis_ok = False
    try:
        conn = get_db_connection()
        conn.close()
        db_ok = True
    except Exception:
        pass

    try:
        r = get_redis_connection()
        r.ping()
        redis_ok = True
    except Exception:
        pass

    if db_ok and redis_ok:
        return {"status": "HEALTHY", "database": "CONNECTED", "cache": "CONNECTED"}
    raise HTTPException(status_code=503, detail={"status": "UNHEALTHY", "database": db_ok, "cache": redis_ok})

@app.get("/")
def read_root():
    return {"service": "order-api", "version": "1.0.0", "status": "active"}

@app.post("/orders")
def create_order(item: str = "Laptop", qty: int = 1):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO orders (item_name, quantity) VALUES (%s, %s) RETURNING id;", (item, qty))
    order_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()

    r = get_redis_connection()
    r.incr("order_count")
    r.lpush("task_queue", f"OrderCreated:{order_id}")

    return {"order_id": order_id, "item": item, "quantity": qty, "status": "queued"}

@app.get("/stats")
def read_stats():
    r = get_redis_connection()
    count = r.get("order_count")
    return {"total_orders": int(count) if count else 0}
LAB_FILE_EOF_3
```

### `starter/app/requirements.txt`

```bash
mkdir -p "$(dirname -- starter/app/requirements.txt)"
cat > starter/app/requirements.txt <<'LAB_FILE_EOF_4'
fastapi==0.110.0
uvicorn==0.28.0
psycopg2-binary==2.9.9
redis==5.0.3
LAB_FILE_EOF_4
```

### `starter/app/worker.py`

```bash
mkdir -p "$(dirname -- starter/app/worker.py)"
cat > starter/app/worker.py <<'LAB_FILE_EOF_5'
import os
import time
import redis

REDIS_HOST = os.getenv("REDIS_HOST", "redis-broker")

def run_worker():
    print(f"[Worker] Starting Async Task Consumer connected to {REDIS_HOST}...")
    r = redis.Redis(host=REDIS_HOST, port=6379, socket_timeout=5)
    
    while True:
        try:
            task = r.brpop("task_queue", timeout=2)
            if task:
                task_data = task[1].decode("utf-8")
                print(f"[Worker] Processing background task: {task_data}")
                time.sleep(0.5)
                print(f"[Worker] Task completed successfully: {task_data}")
        except Exception as e:
            print(f"[Worker] Error polling task queue: {e}")
            time.sleep(2)

if __name__ == "__main__":
    run_worker()
LAB_FILE_EOF_5
```

### `starter/compose.override.yaml`

```bash
mkdir -p "$(dirname -- starter/compose.override.yaml)"
cat > starter/compose.override.yaml <<'LAB_FILE_EOF_6'
# ==============================================================================
# Developer Local Override (compose.override.yaml)
# Automatically merged by Docker Compose in local development environments
# ==============================================================================

services:
  order-api:
    environment:
      - ENVIRONMENT=development
      - DEBUG=true
    volumes:
      - ./app:/app:rw
    command: ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

  # Expose database ports ONLY during local development for tools like DBeaver/TablePlus
  postgres-db:
    ports:
      - "127.0.0.1:5432:5432"

  redis-broker:
    ports:
      - "127.0.0.1:6379:6379"
LAB_FILE_EOF_6
```

### `starter/compose.prod.yaml`

```bash
mkdir -p "$(dirname -- starter/compose.prod.yaml)"
cat > starter/compose.prod.yaml <<'LAB_FILE_EOF_7'
# ==============================================================================
# Production Hardening Override (compose.prod.yaml)
# Applied via: docker compose -f compose.yaml -f compose.prod.yaml up -d
# ==============================================================================

services:
  gateway:
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 128M

  order-api:
    environment:
      - ENVIRONMENT=production
      - DEBUG=false
    deploy:
      resources:
        limits:
          cpus: "1.00"
          memory: 384M
        reservations:
          memory: 128M

  postgres-db:
    deploy:
      resources:
        limits:
          cpus: "1.00"
          memory: 512M

  redis-broker:
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 128M
LAB_FILE_EOF_7
```

### `starter/compose.yaml`

```bash
mkdir -p "$(dirname -- starter/compose.yaml)"
cat > starter/compose.yaml <<'LAB_FILE_EOF_8'
# ==============================================================================
# Enterprise Docker Compose Base Architecture (compose.yaml)
# Implements: Extension Fields, Tiered Networks, True Healthchecks & Profiles
# ==============================================================================

x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

x-app-defaults: &app-defaults
  restart: unless-stopped
  logging: *default-logging
  deploy:
    resources:
      limits:
        cpus: "0.50"
        memory: 256M
      reservations:
        cpus: "0.10"
        memory: 64M

services:
  # 1. Edge / Ingress Reverse Proxy
  gateway:
    image: nginx:1.27-alpine
    restart: unless-stopped
    ports:
      - "${GATEWAY_PORT:-8080}:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - gateway_net
    depends_on:
      order-api:
        condition: service_healthy
    logging: *default-logging

  # 2. Dual-Homed Application Web Service
  order-api:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: enterprise-order-api:1.0.0
    <<: *app-defaults
    environment:
      - ENVIRONMENT=${ENVIRONMENT:-production}
      - DB_HOST=postgres-db
      - "DB_NAME=${POSTGRES_DB:?Error: POSTGRES_DB is required}"
      - "DB_USER=${POSTGRES_USER:?Error: POSTGRES_USER is required}"
      - "DB_PASS=${POSTGRES_PASSWORD:?Error: POSTGRES_PASSWORD is required}"
      - REDIS_HOST=redis-broker
    networks:
      - gateway_net
      - data_net
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/healthz || exit 1"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    depends_on:
      postgres-db:
        condition: service_healthy
      redis-broker:
        condition: service_healthy

  # 3. Private Relational Database (No Published Host Ports!)
  postgres-db:
    image: postgres:16.4-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: "${POSTGRES_DB:?Error: POSTGRES_DB is required}"
      POSTGRES_USER: "${POSTGRES_USER:?Error: POSTGRES_USER is required}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD:?Error: POSTGRES_PASSWORD is required}"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - data_net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 5
      start_period: 5s
    deploy:
      resources:
        limits:
          memory: 512M
    logging: *default-logging

  # 4. Private In-Memory Cache & Message Broker (No Published Host Ports!)
  redis-broker:
    image: redis:7.4-alpine
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--maxmemory", "128mb", "--maxmemory-policy", "allkeys-lru"]
    volumes:
      - redis_data:/data
    networks:
      - data_net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 2s
      retries: 3
    logging: *default-logging

  # 5. Background Asynchronous Task Worker (Profile: worker)
  queue-worker:
    profiles: ["worker"]
    build:
      context: ./app
      dockerfile: Dockerfile
    image: enterprise-queue-worker:1.0.0
    command: ["python", "worker.py"]
    <<: *app-defaults
    environment:
      - REDIS_HOST=redis-broker
    networks:
      - data_net
    depends_on:
      redis-broker:
        condition: service_healthy

  # 6. Observability Metrics Exporter (Profile: monitoring)
  redis-exporter:
    profiles: ["monitoring"]
    image: oliver006/redis_exporter:v1.67.0-alpine
    environment:
      - REDIS_ADDR=redis://redis-broker:6379
    networks:
      - data_net
    restart: unless-stopped
    logging: *default-logging

  # 7. Diagnostic & Network Troubleshooting Container (Profile: debug)
  debug-tools:
    profiles: ["debug"]
    image: curlimages/curl:8.10.1
    entrypoint: ["sleep", "infinity"]
    networks:
      - gateway_net
      - data_net

networks:
  gateway_net:
    driver: bridge
  data_net:
    driver: bridge
    internal: true

volumes:
  postgres_data:
  redis_data:
LAB_FILE_EOF_8
```

### `starter/nginx.conf`

```bash
mkdir -p "$(dirname -- starter/nginx.conf)"
cat > starter/nginx.conf <<'LAB_FILE_EOF_9'
events {
  worker_connections 1024;
}

http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  upstream backend_api {
    server order-api:8000;
    keepalive 32;
  }

  server {
    listen 80;
    server_name localhost;

    location /healthz {
      access_log off;
      proxy_pass http://backend_api/healthz;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
      proxy_pass http://backend_api;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_connect_timeout 5s;
      proxy_read_timeout 30s;
    }
  }
}
LAB_FILE_EOF_9
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_10'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Stopping the lab-doc-13 Docker Compose stack..."
docker compose -p lab-doc-13 --profile "*" -f compose.yaml -f compose.prod.yaml \
  down -v --remove-orphans 2>/dev/null || true
echo "==> Cleanup complete."
LAB_FILE_EOF_10
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_11'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
echo "==> Cleaning existing containers..."
bash "$script_dir/cleanup.sh"
echo "==> Restoring starter templates to the current directory..."
cp -a "$script_dir/../starter/." .
echo "==> LAB-DOC-13 reset completed."
LAB_FILE_EOF_11
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_12'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Validating LAB-DOC-13 production Compose patterns..."
project=lab-doc-13
export POSTGRES_DB=${POSTGRES_DB:-order_db}
export POSTGRES_USER=${POSTGRES_USER:-order_user}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-training-only-password}
export GATEWAY_PORT=${GATEWAY_PORT:-8080}
compose=(docker compose -p "$project" -f compose.yaml -f compose.prod.yaml)
cleanup() { "${compose[@]}" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

"${compose[@]}" config --quiet
"${compose[@]}" up -d --build --wait

response=$(curl --fail --silent "http://localhost:${GATEWAY_PORT}/healthz")
if ! echo "$response" | grep -q '"status":"HEALTHY"' || \
   ! echo "$response" | grep -q '"database":"CONNECTED"' || \
   ! echo "$response" | grep -q '"cache":"CONNECTED"'; then
  echo "[FAIL] Gateway did not prove API, database and cache health: $response" >&2
  exit 1
fi

postgres_container=$("${compose[@]}" ps -q postgres-db)
redis_container=$("${compose[@]}" ps -q redis-broker)
postgres_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "5432/tcp")}}' "$postgres_container")
redis_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "6379/tcp")}}' "$redis_container")
if [[ "$postgres_binding" != "null" || "$redis_binding" != "null" ]]; then
  echo "[FAIL] PostgreSQL or Redis is exposed to the host." >&2
  exit 1
fi

profiles=$(docker compose -f compose.yaml --profile worker --profile monitoring config --services)
grep -qx 'queue-worker' <<<"$profiles"
grep -qx 'redis-exporter' <<<"$profiles"
echo "[PASS] LAB-DOC-13 health, isolation, profiles and production overrides verified."
LAB_FILE_EOF_12
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

Bu labın amacı, Docker Compose kullanarak kurumsal düzeyde **Production-Ready** konteyner orkestrasyon modellerini uygulamalı olarak hayata geçirmektir:

- **Çevre İzolasyonu (Multi-File Compose):** Geliştirme (`compose.override.yaml`) ve canlı (`compose.prod.yaml`) ortamlarını tek bir temel (`compose.yaml`) üzerinde DRY (Don't Repeat Yourself) prensibiyle birleştirmek.
- **Yeniden Kullanılabilir Bloklar (YAML Anchors & Extensions):** `x-logging`, `x-app-defaults` ve `<<: *anchor` sentaksı ile yüzlerce satırlık tekrarı önlemek.
- **Ağ Güvenliği (Dual Isolated Networks):** Dış dünyaya açık `gateway_net` ile sadece dahili servislerin konuştuğu `data_net` ağlarını birbirinden tamamen izole etmek.
- **Servis Sağlığı ve Bağımlılık Zinciri:** `healthcheck` ve `depends_on: condition: service_healthy` ile veritabanı veya kuyruk hazır olmadan uygulamanın başlamasını engellemek.
- **Kaynak Kısıtlama ve Log Rotasyonu:** `deploy.resources.limits` ile CPU/RAM sınırları koymak; logların diski doldurmaması için `json-file` rotasyonu tanımlamak.
- **İsteğe Bağlı Servis Profilleri (Profiles):** `--profile worker` ve `--profile monitoring` ile isteğe bağlı alt servisleri yönetmek.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ve Docker Compose v2 ortamınızın kurulu olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine ve Compose Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

Hızlı sistem ön kontrolü:

```bash
docker compose version
docker info | grep -E "Server Version|Operating System"
```

---

## Mimari ve Ağ İzolasyon Modeli

```text
                        [ Dış Dünya / İstemci ]
                                   | (Port 8080)
                                   v
+-------------------------------------------------------------------------+
|                              NGINX Gateway                              |
+-------------------------------------------------------------------------+
       |                                                    |
   (gateway_net: 172.28.0.0/16)                             |
       v                                                    |
+------------------------------+                            |
|        FastAPI Core          |                            |
+------------------------------+                            |
       |                                                    |
   (data_net: 172.29.0.0/16)                                |
       +--------------------------------+                   |
       |                                |                   |
       v                                v                   v
+----------------+              +---------------+   +-------------------+
|  PostgreSQL 16 |              |   Redis 7     |   | Background Worker |
| (5432 - Gizli) |              | (6379 - Gizli)|   | (Profile: worker) |
+----------------+              +---------------+   +-------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş ve Ortam Değişkenleri

```bash
mkdir -p ~/labs/LAB-DOC-13
cd ~/labs/LAB-DOC-13
```

ZIP indirdiyseniz `unzip LAB-DOC-13.zip && cd LAB-DOC-13` komutunu çalıştırın veya dosyaları oluşturun.

Ortam değişkenleri dosyasını hazırlayın ve dosya izinlerini kısıtlayın:

```bash
cp .env.example .env
chmod 600 .env
```

---

### Adım 2: Compose Dosyalarının ve YAML Uzantılarının İncelenmesi

Temel `compose.yaml` dosyasındaki YAML Anchors ve Extensions yapısını inceleyin:

```bash
cat compose.yaml
```

Önemli tasarım desenleri:
1. **`x-logging`:** Tüm servislere tek satırda log limiti (`max-size: "10m"`, `max-file: "3"`) uygular.
2. **`x-app-defaults`:** Ortak ortam değişkenlerini ve restart politikalarını tanımlar.
3. **`networks`:**
   - `gateway_net`: Nginx ve API arasındaki HTTP trafiğini taşır.
   - `data_net`: API, Worker, Postgres ve Redis arasındaki veri trafiğini izole eder (`internal: true`).

---

### Adım 3: Birleştirilmiş (Rendered) Yapılandırmayı Doğrulama

Production ortamı için `compose.yaml` ve `compose.prod.yaml` dosyalarını birleştirerek nihai çıktıyı test edin:

```bash
# Sentaks ve değişken doğrulaması
docker compose --env-file .env -f compose.yaml -f compose.prod.yaml config --quiet

# Birleştirilmiş tam konfigürasyonu görüntüleyin
docker compose --env-file .env -f compose.yaml -f compose.prod.yaml config
```

---

### Adım 4: Production Stack'i Başlatma ve Sağlık Kontrolü

Tüm servisleri production modunda arka planda başlatın ve tüm servislerin `healthy` durumuna gelmesini bekleyin:

```bash
docker compose -p lab-doc-13 --env-file .env   -f compose.yaml -f compose.prod.yaml up -d --build --wait
```

Servis durumlarını ve port izolasyonunu kontrol edin:

```bash
docker compose -p lab-doc-13 --env-file .env   -f compose.yaml -f compose.prod.yaml ps
```

> [!NOTE]
> Postgres (`5432`) ve Redis (`6379`) portları dışarıya (host) açık olmamalı; sadece Nginx (`8080`) erişilebilir olmalıdır.

---

### Adım 5: Sağlık Uç Noktası (Healthz) Testi

```bash
curl -i http://localhost:8080/healthz
```

Beklenen HTTP 200 JSON Yanıtı:
```json
{
  "status": "HEALTHY",
  "database": "CONNECTED",
  "cache": "CONNECTED"
}
```

---

### Adım 6: İsteğe Bağlı Profilleri (Profiles) Çalıştırma

Worker servisi varsayılan olarak başlamaz; sadece `--profile worker` belirtildiğinde devreye girer:

```bash
# Worker profilini inceleyin
docker compose --env-file .env -f compose.yaml --profile worker config --services

# Worker servisini ayağa kaldırın
docker compose -p lab-doc-13 --env-file .env   -f compose.yaml -f compose.prod.yaml --profile worker up -d worker
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

Aşağıdaki soruları yanıtlamaya çalışın; ardından çözümü görmek için kutucuklara tıklayın:

??? question "Soru 1: Docker Compose'da `compose.yaml` ve `compose.override.yaml` dosyaları varsayılan olarak nasıl davranır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `docker compose up` komutunu hiçbir `-f` bayrağı vermeden çalıştırdığınızda, Docker Compose otomatik olarak önce `compose.yaml` (veya `docker-compose.yml`) dosyasını, ardından dizinde varsa `compose.override.yaml` dosyasını okuyup ikisini birleştirir (merge). Bu mekanizma geliştiricilerin yerel portları veya volume bağlamalarını ana dosyayı bozmadan ezmesine olanak tanır. Canlı ortamda ise `-f compose.yaml -f compose.prod.yaml` şeklinde açıkça belirtilir.

??? question "Soru 2: YAML dosyasında `x-logging: &default-logging` ve `<<: *default-logging` sentaksı ne anlama gelir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `x-` ile başlayan alanlar **Docker Compose Extension Fields** olarak adlandırılır ve Compose tarafından doğrudan bir servis olarak algılanmaz. `&default-logging` bir YAML Çapası (Anchor) oluşturur. `<<: *default-logging` (Merge Key) ise bu çapadaki tüm tanımları hedef servisin altına kopyalar. Böylece 10 farklı servise aynı loglama ayarını tek satırda uygulayabilirsiniz.

??? question "Soru 3: Bir veritabanı konteynerinin `ports:` yerine yalnızca internal bir network'e bağlanmasının güvenlik avantajı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Eğer `ports: - "5432:5432"` tanımlanırsa, PostgreSQL doğrudan host makinenin tüm ağ arayüzlerine (0.0.0.0) açılır. Bu da internete açık bir sunucuda veritabanının dışarıdan doğrudan brute-force saldırılarına maruz kalması demektir. Port açılmayıp yalnızca `data_net` ağına bağlandığında, veritabanına YALNIZCA aynı Docker ağına bağlı yetkili API konteyneri erişebilir.

??? question "Soru 4: `depends_on: condition: service_healthy` ile klasik `depends_on:` arasındaki fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Klasik `depends_on:` sadece bağımlı konteynerin süreç olarak başlatılmasını (Process Started) bekler; veritabanının sorgu kabul edip etmediğine bakmaz. Bu durum uygulamanın "Connection Refused" hatasıyla çökmesine yol açabilir. `service_healthy` ise hedef konteynerin `healthcheck` komutu (ör. `pg_isready`) `0` dönene kadar bekler ve uygulamayı ancak veritabanı tamamen hazır olduğunda başlatır.

??? question "Soru 5: `docker compose down` komutuna `-v` parametresi eklenmezse Persistent Volume verileri silinir mi?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Hayır, silinmez! `docker compose down` yalnızca konteynerleri ve ağları siler; `volumes:` altında tanımlanan Named Volume'lar korunur. Veritabanını tamamen sıfırlamak ve verileri silmek için `docker compose down -v` komutunu çalıştırmanız gerekir.

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Sorun Giderme

- **Veritabanı Parola Hatası:** `.env` dosyasındaki `POSTGRES_USER`, `POSTGRES_PASSWORD` ve `POSTGRES_DB` değişkenlerinin eksiksiz olduğunu doğrulayın.
- **Port Meşgul:** 8080 portu meşgulse `docker ps` veya `lsof -i :8080` ile kontrol edin.
- **Servis Sağlıksız:** Belirli bir servisin loglarını `docker compose -p lab-doc-13 logs <servis_adi>` ile inceleyin.

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak ve Referanslar

Bu lab, Production Docker Compose Reference Architecture ve Docker Best Practices kılavuzlarından uyarlanmıştır.
