# LAB-DOC-05 — Multi-Container Orchestration with Docker Compose & Healthchecks

## Metadata
- **Seviye:** PRACTITIONER
- **Önerilen Gün:** Gün 2
- **Tahmini Süre:** 60 dk
- **Gerekli Profil:** `docker`
- **Host Portları:** `8080:8080` (API), `5432` (Internal DB), `6379` (Internal Redis)
- **Çalışma Dizini:** `~/devops-workspace/labs/LAB-DOC-05`

---

## 1. Lab Senaryosu
Modern mikroservis uygulamaları nadiren tek bir bileşenden oluşur. Tipik bir e-ticaret veya sipariş mimarisinde web API'si, kalıcı veri saklayan bir ilişkisel veritabanı (PostgreSQL) ve yüksek performanslı önbellekleme katmanına (Redis) ihtiyaç duyar. Eğer API servisi, veritabanı henüz TCP soketini dinlemeye ve sorgu kabul etmeye başlamadan önce ayağa kalkarsa bağlantı hatası alarak çöker. Bu çalışmada Docker Compose kullanılarak çok katmanlı bir mimari orkestre edilir; `condition: service_healthy` direktifi ile deterministik başlatma sırası garanti altına alınır.

## 2. Amaç
Docker Compose (`compose.yaml`) ile 3 katmanlı (Web API + PostgreSQL + Redis) bir servis kümesini ayağa kaldırmak, servisler arası DNS tabanlı iletişim ve izole bridge ağı kurmak, `healthcheck` mekanizmaları ile bağımlılık sırasını yönetmek ve API üzerinden veritabanı ile önbellek entegrasyonunu doğrulamak.

## 3. Mimari / Akış
```text
                         [ Host Port: 8080 ]
                                 |
                                 v
                 +-------------------------------+
                 |    order-api (FastAPI)        |
                 +-------------------------------+
                         |               |
            (TCP: 5432)  |               | (TCP: 6379)
                         v               v
                 +---------------+ +---------------+
                 |  postgres-db  | |  redis-cache  |
                 | (pg_isready)  | | (redis-ping)  |
                 +---------------+ +---------------+
                         |
                 [ Volume: db_data ]
```

## 4. Ön Koşullar
- Docker Engine ve Docker Compose v2 çalışır durumda olmalıdır
- Host üzerinde 8080 portu boş olmalıdır
- `jq` ve `curl` araçları kurulu olmalıdır
- Önceden tamamlanması önerilen lablar: `LAB-DOC-03`, `LAB-DOC-04`

Aşağıdaki komutla çalışma ortamını hazırlayın:
```bash
docker compose version
mkdir -p ~/devops-workspace/labs/LAB-DOC-05/app
cd ~/devops-workspace/labs/LAB-DOC-05
```

## 5. Adım Adım Uygulama

### Adım 1 — Uygulama Kaynak Kodlarını ve Dockerfile'ı Oluşturma
API servisinin kodlarını, kütüphane bağımlılıklarını ve Dockerfile'ını hazırlayın:
```bash
cat <<'EOF' > app/requirements.txt
fastapi==0.110.0
uvicorn==0.28.0
psycopg2-binary==2.9.9
redis==5.0.3
EOF

cat <<'EOF' > app/main.py
import os
import time
from fastapi import FastAPI, HTTPException
import psycopg2
import redis
import uvicorn

app = FastAPI(title="Multi-Tier Order Service")

DB_HOST = os.getenv("DB_HOST", "postgres-db")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "postgres")
DB_NAME = os.getenv("DB_NAME", "orderdb")
REDIS_HOST = os.getenv("REDIS_HOST", "redis-cache")

def get_db():
    return psycopg2.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASS, dbname=DB_NAME
    )

def get_redis():
    return redis.Redis(host=REDIS_HOST, port=6379, db=0, decode_responses=True)

@app.get("/")
def home():
    r = get_redis()
    hits = r.incr("page_views")
    return {
        "service": "order-api",
        "page_hits_from_redis": hits,
        "database": "connected"
    }

@app.get("/healthz")
def health():
    try:
        conn = get_db()
        conn.close()
        r = get_redis()
        r.ping()
        return {"status": "HEALTHY", "db": "OK", "redis": "OK"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
EOF

cat <<'EOF' > app/Dockerfile
FROM python:3.11-slim-bookworm

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .

EXPOSE 8080
CMD ["python", "main.py"]
EOF
```

### Adım 2 — `compose.yaml` Dosyasını Healthcheck Kurallarıyla Yazma
Servislerin başlatılma koşullarını belirten Compose manifestosunu oluşturun:
```bash
cat <<'EOF' > compose.yaml
services:
  postgres-db:
    image: postgres:16-alpine
    container_name: postgres-db
    environment:
      POSTGRES_DB: orderdb
      POSTGRES_USER: devops
      POSTGRES_PASSWORD: SecretPassword123!
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
    container_name: redis-cache
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
    container_name: order-api
    ports:
      - "8080:8080"
    environment:
      DB_HOST: postgres-db
      DB_USER: devops
      DB_PASS: SecretPassword123!
      DB_NAME: orderdb
      REDIS_HOST: redis-cache
    networks:
      - backend-net
    depends_on:
      postgres-db:
        condition: service_healthy
      redis-cache:
        condition: service_healthy

volumes:
  db_data:

networks:
  backend-net:
    driver: bridge
EOF
```

### Adım 3 — Stack'i Başlatma ve Durumu İnceleme
Tüm servisleri arka planda derleyip ayağa kaldırın:
```bash
docker compose up -d --build
```

### Adım 4 — Servis Sağlık Durumlarını Denetleme
Konteynerlerin durumunu kontrol edin:
```bash
docker compose ps
```

### Adım 5 — API İstekleri ile Veritabanı ve Önbellek Sayaçlarını Test Etme
Web servisine ardışık iki istek göndererek Redis sayacının arttığını gözlemleyin:
```bash
curl -s http://localhost:8080/
curl -s http://localhost:8080/
```

## 6. Beklenen Sonuç
Adım 4'teki `docker compose ps` çıktısı (Tüm servisler `healthy` olmalıdır):
```text
NAME          IMAGE                COMMAND                  SERVICE        STATUS
order-api     ...                  "python main.py"         api-service    running
postgres-db   postgres:16-alpine   "docker-entrypoint.s…"   postgres-db    running (healthy)
redis-cache   redis:7-alpine       "docker-entrypoint.s…"   redis-cache    running (healthy)
```

Adım 5'teki API JSON yanıtları (sayaç artışı görülmelidir):
```json
{"service":"order-api","page_hits_from_redis":1,"database":"connected"}
{"service":"order-api","page_hits_from_redis":2,"database":"connected"}
```

## 7. Doğrulama
Sağlık endpoint'inin hem veritabanı hem de Redis için `OK` döndürdüğünü doğrulayın:
```bash
HEALTH_STATUS=$(curl -sf http://localhost:8080/healthz | jq -r .status)
if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
  echo "VALIDATION SUCCESS: Multi-tier stack is healthy, Redis hits incrementing, PostgreSQL connected."
else
  echo "VALIDATION FAILED: Health endpoint returned $HEALTH_STATUS" && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
`order-api` servisi başlamıyor ve `dependency failed to start: container postgres-db is unhealthy` hatası alınıyor.

### Kanıt
`docker compose logs postgres-db` çıktısında veritabanı bağlantı hatası veya rol eksikliği görülür.

### Kontrol Komutu
```bash
docker compose logs postgres-db | tail -n 20
```

### Muhtemel Neden
`postgres-db` healthcheck komutundaki veritabanı adı (`pg_isready -d orderdb`) ile `POSTGRES_DB: orderdb` parametresi uyuşmamaktadır.

### Çözüm
`compose.yaml` dosyasındaki ortam değişkenleri ile healthcheck parametrelerini eşitleyin ve stack'i yeniden başlatın:
```bash
docker compose down
docker compose up -d
```

### Tekrar Doğrulama
```bash
docker compose ps
# Tüm servisler Up veya Healthy görünmelidir.
```

## 9. Temizlik / Sıfırlama
Compose stack'ini, bağlı volume'leri ve bridge ağını silin:
```bash
docker compose down -v
rm -rf ~/devops-workspace/labs/LAB-DOC-05
```

## 10. Production Notu
Üretim ortamlarında veritabanı (PostgreSQL) ve önbellek (Redis) portları kesinlikle `ports: - 5432:5432` şeklinde host dışına açılmamalıdır; sadece izole `backend-net` bridge ağı üzerinden mikroservislerin erişimine sunulmalıdır. Ayrıca `depends_on: [postgres-db]` direktifi yalnızca konteynerin başladığını garanti eder; uygulamanın çökmemesi için mutlaka `condition: service_healthy` kullanılmalıdır.

## 11. Challenge
`compose.yaml` dosyasına bir `nginx` servisi ekleyerek gelen dış HTTP isteklerini port 80 üzerinden karşılayıp `order-api:8080` servisine yönlendiren bir reverse proxy katmanı kurun.
