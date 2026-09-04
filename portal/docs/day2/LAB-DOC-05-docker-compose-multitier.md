# LAB-DOC-05 — Docker Compose ile Çok Katmanlı Mimari (Multi-Tier Orchestration)

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-05.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-05.zip && cd LAB-DOC-05`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-05
cd ~/labs/LAB-DOC-05
```

### `starter/app/Dockerfile`

```bash
mkdir -p "$(dirname -- starter/app/Dockerfile)"
cat > starter/app/Dockerfile <<'LAB_FILE_EOF_1'
FROM python:3.11-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
RUN useradd --uid 10001 appuser
USER 10001
EXPOSE 8080
CMD ["python", "main.py"]
LAB_FILE_EOF_1
```

### `starter/app/main.py`

```bash
mkdir -p "$(dirname -- starter/app/main.py)"
cat > starter/app/main.py <<'LAB_FILE_EOF_2'
import os

import psycopg2
import redis
import uvicorn
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Multi-Tier Order Service")


def database_connection():
    return psycopg2.connect(host=os.environ["DB_HOST"], user=os.environ["DB_USER"], password=os.environ["DB_PASS"], dbname=os.environ["DB_NAME"], connect_timeout=3)


def redis_connection():
    return redis.Redis(host=os.environ["REDIS_HOST"], port=6379, decode_responses=True)


@app.get("/")
def home():
    return {"service": "order-api", "page_hits_from_redis": redis_connection().incr("page_views")}


@app.get("/healthz")
def health():
    try:
        connection = database_connection()
        connection.close()
        redis_connection().ping()
        return {"status": "HEALTHY", "db": "OK", "redis": "OK"}
    except Exception as exc:
        raise HTTPException(status_code=503, detail="dependency check failed") from exc


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
LAB_FILE_EOF_2
```

### `starter/app/requirements.txt`

```bash
mkdir -p "$(dirname -- starter/app/requirements.txt)"
cat > starter/app/requirements.txt <<'LAB_FILE_EOF_3'
fastapi==0.110.0
uvicorn==0.28.0
psycopg2-binary==2.9.9
redis==5.0.3
LAB_FILE_EOF_3
```

### `starter/compose.yaml`

```bash
mkdir -p "$(dirname -- starter/compose.yaml)"
cat > starter/compose.yaml <<'LAB_FILE_EOF_4'
# Starter compose template
services:
  # TODO: Add postgres-db service with healthcheck
  # TODO: Add redis-cache service with healthcheck
  # TODO: Add api-service with depends_on condition: service_healthy
LAB_FILE_EOF_4
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_5'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Cleaning up LAB-DOC-05..."
docker compose -p lab-doc-05 down -v --remove-orphans 2>/dev/null || true
echo "Cleanup completed."
LAB_FILE_EOF_5
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_6'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Resetting LAB-DOC-05..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
cp -a "$script_dir/../starter/." .
echo "Reset completed. Starter files restored."
LAB_FILE_EOF_6
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_7'
#!/usr/bin/env bash
set -euo pipefail

echo "==> Validating LAB-DOC-05 Multi-Tier Compose Stack..."
export LAB_POSTGRES_PASSWORD=${LAB_POSTGRES_PASSWORD:-training-only-password}
project=lab-doc-05
cleanup() { docker compose -p "$project" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker compose -p "$project" config --quiet
docker compose -p "$project" up -d --build --wait
health=$(curl --fail --silent http://localhost:8080/healthz)
first=$(curl --fail --silent http://localhost:8080/ | jq -r .page_hits_from_redis)
second=$(curl --fail --silent http://localhost:8080/ | jq -r .page_hits_from_redis)

if ! echo "$health" | jq -e '.status == "HEALTHY" and .db == "OK" and .redis == "OK"' >/dev/null; then
  echo "[FAIL] API did not prove PostgreSQL and Redis connectivity: $health" >&2
  exit 1
fi
if [[ "$second" -ne $((first + 1)) ]]; then
  echo "[FAIL] Redis counter did not increment: $first -> $second" >&2
  exit 1
fi
postgres_container=$(docker compose -p "$project" ps -q postgres-db)
redis_container=$(docker compose -p "$project" ps -q redis-cache)
postgres_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "5432/tcp")}}' "$postgres_container")
redis_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "6379/tcp")}}' "$redis_container")
if [[ "$postgres_binding" != "null" || "$redis_binding" != "null" ]]; then
  echo "[FAIL] A data service port is exposed on the host." >&2
  exit 1
fi
echo "[PASS] LAB-DOC-05 API, PostgreSQL, Redis and network isolation verified."
LAB_FILE_EOF_7
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

- Çok servisli mikroservis mimarisini (**API + PostgreSQL + Redis**) Docker Compose ile orkestre etmek.
- Servisleri izole bir `backend-net` bridge ağı üzerinden dahili DNS ile bağlamak.
- `healthcheck` ve `depends_on: condition: service_healthy` kullanarak servislerin doğru sırada ve sağlıklı açılmasını garantilemek.
- İnteraktif Compose orkestrasyon alıştırmalarını çözmek.

---

## Ön Koşullar

Çalışma ortamınızda Docker ve Docker Compose servislerinin çalıştığından emin olun:

```bash
docker version
docker compose version
```

> Komutlar hata vermeden tamamlanmalıdır. `8080` portunun boş olduğundan emin olun.

---

## Adımlar

### 1. Çalışma Dizinini ve API Uygulamasını Hazırlayın

Standart laboratuvar çalışma dizininizi oluşturun ve içine geçin:

```bash
mkdir -p ~/labs/LAB-DOC-05/app
cd ~/labs/LAB-DOC-05
```

Eğer laboratuvar paketini indirdiyseniz başlangıç dosyalarını kopyalayabilirsiniz:

```bash
cp -a starter/. . 2>/dev/null || true
```

Veya uygulama dosyalarını doğrudan oluşturun:

```bash
cat <<'EOF' > app/main.py
from fastapi import FastAPI, HTTPException
import psycopg2
import redis
import os

app = FastAPI(title="Order API")

DB_HOST = os.getenv("DB_HOST", "postgres-db")
DB_USER = os.getenv("DB_USER", "devops")
DB_PASS = os.getenv("DB_PASS", "training-only-password")
DB_NAME = os.getenv("DB_NAME", "orderdb")
REDIS_HOST = os.getenv("REDIS_HOST", "redis-cache")

@app.get("/healthz")
def healthz():
    try:
        conn = psycopg2.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, dbname=DB_NAME, connect_timeout=3)
        conn.close()
        r = redis.Redis(host=REDIS_HOST, port=6379, socket_connect_timeout=3)
        r.ping()
        return {"status": "healthy", "database": "OK", "redis": "OK"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def read_root():
    r = redis.Redis(host=REDIS_HOST, port=6379, socket_connect_timeout=3)
    visits = r.incr("visit_count")
    return {"message": "Welcome to Multi-Tier Order API", "visits": visits}
EOF
```

Bağımlılık ve Dockerfile dosyalarını oluşturun:

```bash
cat <<'EOF' > app/requirements.txt
fastapi==0.110.0
uvicorn==0.28.0
psycopg2-binary==2.9.9
redis==5.0.3
EOF

cat <<'EOF' > app/Dockerfile
FROM python:3.11-alpine
WORKDIR /app
RUN apk add --no-cache libpq
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
EOF
```

---

### 2. Çok Katmanlı `compose.yaml` Dosyasını Oluşturun

```bash
cat <<'YAML' > compose.yaml
services:
  postgres-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: orderdb
      POSTGRES_USER: devops
      POSTGRES_PASSWORD: ${LAB_POSTGRES_PASSWORD:?LAB_POSTGRES_PASSWORD is required}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - backend-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U devops -d orderdb"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 5s

  redis-cache:
    image: redis:7-alpine
    networks:
      - backend-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 3

  api-service:
    build:
      context: ./app
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      DB_HOST: postgres-db
      DB_USER: devops
      DB_PASS: ${LAB_POSTGRES_PASSWORD:?LAB_POSTGRES_PASSWORD is required}
      DB_NAME: orderdb
      REDIS_HOST: redis-cache
    networks:
      - backend-net
    depends_on:
      postgres-db:
        condition: service_healthy
      redis-cache:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz')\""]
      interval: 3s
      timeout: 3s
      retries: 20

volumes:
  db_data:

networks:
  backend-net:
    driver: bridge
YAML
```

---

### 3. Ortam Değişkenini Tanımlayın ve Stack'i Başlatın

```bash
export LAB_POSTGRES_PASSWORD='training-only-password'
docker compose -p lab-doc-05 up -d --build --wait
docker compose -p lab-doc-05 ps
```

---

### 4. Servis İletişimini ve Ziyaretçi Sayacını Test Edin

Sağlık ucunu kontrol edin:

```bash
curl http://localhost:8080/healthz
```

Ana uca ardı ardına istek atarak Redis sayacının arttığını doğrulayın:

```bash
curl http://localhost:8080/
curl http://localhost:8080/
curl http://localhost:8080/
```

---

## 💡 Docker Compose İnteraktif Pratik Alıştırmaları

#### Soru 1: Çalışan Servislerin Loglarını Canlı İzleme
> **Görev:** Yalnızca `api-service` servisinin loglarını canlı akış modunda izleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker compose -p lab-doc-05 logs -f api-service
    # Çıkış: Ctrl + C
    ```

---

#### Soru 2: Çalışan Servislerden Birini Yeniden Başlatma
> **Görev:** `redis-cache` servisini diğer servislere dokunmadan yeniden başlatın.

??? tip "💡 Çözümü Göster"
    ```bash
    docker compose -p lab-doc-05 restart redis-cache
    docker compose -p lab-doc-05 ps redis-cache
    ```

---

#### Soru 3: Servis İçinde İnteraktif Komut Çalıştırma
> **Görev:** `redis-cache` konteyneri içinde `redis-cli KEYS "*"` komutunu çalıştırıp ziyaretçi sayacı anahtarını görüntüleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker compose -p lab-doc-05 exec redis-cache redis-cli KEYS "*"
    docker compose -p lab-doc-05 exec redis-cache redis-cli GET visit_count
    ```

---

## Beklenen Sonuç

```json
{"status":"healthy","database":"OK","redis":"OK"}
{"message":"Welcome to Multi-Tier Order API","visits":3}
```

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Sorun Giderme

- **Sağlık Hatası (500 Internal Error):** `docker compose -p lab-doc-05 logs api-service` çıktısını kontrol edin.
- **Postgres Bağlantı Hatası:** `LAB_POSTGRES_PASSWORD` değişkeninin doğru export edildiğinden emin olun.
- **Port Çakışması:** `8080` portunu kullanan başka bir konteyner varsa durdurun.

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak

- [Hakan Bayraktar — book-review-app Repository](https://github.com/hakanbayraktar/book-review-app)
- [Hakan Bayraktar — Docker Commands Cheat Sheet with Examples](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f)

