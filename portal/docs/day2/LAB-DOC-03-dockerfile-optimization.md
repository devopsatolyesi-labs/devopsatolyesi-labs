# LAB-DOC-03 — Python API için Dockerfile, Katman Optimizasyonu ve İmaj Yönetimi

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-03.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-03.zip && cd LAB-DOC-03`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-03
cd ~/labs/LAB-DOC-03
```

### `starter/.dockerignore`

```bash
mkdir -p "$(dirname -- starter/.dockerignore)"
cat > starter/.dockerignore <<'LAB_FILE_EOF_1'
.git
__pycache__
*.py[cod]
.venv
venv
LAB_FILE_EOF_1
```

### `starter/Dockerfile.bloated`

```bash
mkdir -p "$(dirname -- starter/Dockerfile.bloated)"
cat > starter/Dockerfile.bloated <<'LAB_FILE_EOF_2'
# ==============================================================================
# ANTI-PATTERN DOCKERFILE (Bloated Image Example - DO NOT USE IN PRODUCTION)
# Results in ~1.28 GB image size due to:
#  1. Fat Ubuntu-based full Python image
#  2. Unnecessary build tools (gcc, make, vim)
#  3. Uncleaned apt package caches
#  4. Missing --no-cache-dir in pip
#  5. Copying all files before installing requirements (breaks cache)
# ==============================================================================
FROM python:3.11

# Anti-Pattern 1: Installing extra packages without cleanup
RUN apt-get update
RUN apt-get install -y build-essential gcc g++ make curl wget git vim

WORKDIR /app

# Anti-Pattern 2: Copying entire context before pip breaks layer cache!
COPY . /app

# Anti-Pattern 3: Pip cache is preserved in image layers
RUN pip install -r src/requirements.txt

EXPOSE 8000
CMD ["python", "src/app.py"]
LAB_FILE_EOF_2
```

### `starter/Dockerfile.multistage`

```bash
mkdir -p "$(dirname -- starter/Dockerfile.multistage)"
cat > starter/Dockerfile.multistage <<'LAB_FILE_EOF_3'
# ==============================================================================
# PRODUCTION MULTI-STAGE HARDENED DOCKERFILE (Alpine Minimal)
# Reduces size from ~1.28 GB to ~48 MB (-96% reduction)
# Runs as non-root user (UID 10001)
# ==============================================================================

# ----------------- STAGE 1: BUILDER -----------------
FROM python:3.11-alpine AS builder

WORKDIR /build

RUN apk add --no-cache gcc musl-dev libffi-dev

COPY src/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ----------------- STAGE 2: RUNTIME -----------------
FROM python:3.11-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# Copy only installed libraries from builder stage (no compilers or cache)
COPY --from=builder /install /usr/local
COPY src/app.py /app/app.py

# Non-root user for security hardening
RUN adduser -u 10001 -D -s /bin/sh appuser && chown -R appuser:appuser /app
USER 10001

EXPOSE 8000
CMD ["python", "app.py"]
LAB_FILE_EOF_3
```

### `starter/Dockerfile.optimized`

```bash
mkdir -p "$(dirname -- starter/Dockerfile.optimized)"
cat > starter/Dockerfile.optimized <<'LAB_FILE_EOF_4'
# ==============================================================================
# OPTIMIZED SINGLE-STAGE DOCKERFILE (Slim & Cache-Friendly)
# Reduces size from ~1.28 GB to ~165 MB (-87% reduction)
# ==============================================================================
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# Best Practice 1: Copy dependencies first to exploit Docker layer caching
COPY src/requirements.txt /app/requirements.txt

# Best Practice 2: Install with --no-cache-dir
RUN pip install --no-cache-dir -r requirements.txt

# Best Practice 3: Copy only the application source code last
COPY src/app.py /app/app.py

EXPOSE 8000
CMD ["python", "app.py"]
LAB_FILE_EOF_4
```

### `starter/src/app.py`

```bash
mkdir -p "$(dirname -- starter/src/app.py)"
cat > starter/src/app.py <<'LAB_FILE_EOF_5'
from fastapi import FastAPI
import uvicorn
import os

app = FastAPI(title="DevOps Demo API", version="1.0.0")

@app.get("/")
def read_root():
    return {
        "status": "healthy",
        "service": "order-api",
        "environment": os.getenv("APP_ENV", "production")
    }

@app.get("/healthz")
def health_check():
    return {"status": "UP"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app:app", host="0.0.0.0", port=port, log_level="info")
LAB_FILE_EOF_5
```

### `starter/src/requirements.txt`

```bash
mkdir -p "$(dirname -- starter/src/requirements.txt)"
cat > starter/src/requirements.txt <<'LAB_FILE_EOF_6'
fastapi==0.110.0
uvicorn==0.28.0
pydantic==2.6.4
LAB_FILE_EOF_6
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_7'
#!/usr/bin/env bash
# ==============================================================================
# Script: cleanup.sh
# Purpose: Cleans containers and images created during LAB-DOC-03
# ==============================================================================
set -euo pipefail

echo "==> Stopping and removing demo containers..."
docker rm -f demo-api-container 2>/dev/null || true

echo "==> Removing test images..."
docker rmi devops-demo-api:bloated devops-demo-api:slim devops-demo-api:multistage 2>/dev/null || true
registry=${HARBOR_REGISTRY:-localhost:8082}
docker rmi "$registry/devops/order-api:1.0.0" 2>/dev/null || true

echo "==> Cleanup complete."
LAB_FILE_EOF_7
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_8'
#!/usr/bin/env bash
# ==============================================================================
# Script: reset.sh
# Purpose: Resets student workspace to clean starter files
# ==============================================================================
set -euo pipefail

ASSETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Cleaning existing containers and images..."
bash "${ASSETS_DIR}/scripts/cleanup.sh"

echo "==> Restoring starter templates to the current directory..."
cp -a "${ASSETS_DIR}/starter/." .

echo "==> LAB-DOC-03 reset completed."
LAB_FILE_EOF_8
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_9'
#!/usr/bin/env bash
# ==============================================================================
# Script: validate.sh
# Purpose: Validates Docker Image Minimization & Registry Tagging (LAB-DOC-03)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "  VALIDATING IMAGE MINIMIZATION & REGISTRY PUSH (LAB-DOC-03) "
echo "=========================================================="

PASS=0
FAIL=0

log_pass() { echo -e "[\033[32mPASS\033[0m] $1"; PASS=$((PASS+1)); }
log_fail() { echo -e "[\033[31mFAIL\033[0m] $1"; FAIL=$((FAIL+1)); }

# 1. Check Container Health
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/healthz 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
  log_pass "Optimized container responds on port 8000 with HTTP 200 (UP)."
else
  log_fail "Optimized container health check returned HTTP $HTTP_STATUS (expected 200)."
fi

# 2. Check Image Sizes
if docker image inspect devops-demo-api:slim >/dev/null 2>&1; then
  SLIM_SIZE_BYTES=$(docker image inspect devops-demo-api:slim --format '{{.Size}}')
  SLIM_MB=$((SLIM_SIZE_BYTES / 1024 / 1024))
  if [ "$SLIM_MB" -lt 250 ]; then
    log_pass "Single-Stage Slim image size is ${SLIM_MB} MB (< 250 MB target)."
  else
    log_fail "Single-Stage Slim image is unexpectedly large: ${SLIM_MB} MB."
  fi
else
  log_fail "Image 'devops-demo-api:slim' not found locally."
fi

if docker image inspect devops-demo-api:multistage >/dev/null 2>&1; then
  MULTI_SIZE_BYTES=$(docker image inspect devops-demo-api:multistage --format '{{.Size}}')
  MULTI_MB=$((MULTI_SIZE_BYTES / 1024 / 1024))
  if [ "$MULTI_MB" -lt 80 ]; then
    log_pass "Multi-Stage Minimal image size is ${MULTI_MB} MB (< 80 MB target!)."
  else
    log_fail "Multi-Stage image is unexpectedly large: ${MULTI_MB} MB."
  fi
else
  log_fail "Image 'devops-demo-api:multistage' not found locally."
fi

# 3. Check the remote registry manifest, not only the local tag.
REGISTRY=${HARBOR_REGISTRY:-localhost:8082}
REGISTRY_REF="$REGISTRY/devops/order-api:1.0.0"
if docker manifest inspect --insecure "$REGISTRY_REF" >/dev/null 2>&1; then
  log_pass "Harbor manifest verified: $REGISTRY_REF"
else
  log_fail "Harbor manifest '$REGISTRY_REF' not found or authentication failed."
fi

echo "----------------------------------------------------------"
echo "  SUMMARY: PASS=$PASS | FAIL=$FAIL"
echo "----------------------------------------------------------"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  RESULT: \033[32mIMAGE MINIMIZATION & REGISTRY PUBLISHING VALIDATED\033[0m"
  exit 0
else
  echo -e "  RESULT: \033[31mVALIDATION FAILED\033[0m"
  exit 1
fi
LAB_FILE_EOF_9
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

- Python FastAPI / Flask uygulamasını Docker ile konteynerize etmek.
- Dockerfile komut sırası (`COPY requirements.txt` -> `pip install` -> `COPY src/`) ile **Layer Cache** avantajını kavramak.
- `.dockerignore` kullanarak gereksiz dosyaları (`__pycache__`, `.git`, `.env`) imaj dışı bırakmak.
- İmaj katmanlarını `docker history` ile analiz etmek ve imaj boyutlarını karşılaştırmak.

---

## Ön Koşullar

Çalışma ortamınızda Docker servisinin çalıştığından emin olun:

```bash
docker version
```

> Komutlar hata vermeden tamamlanmalıdır. `8000` portunun boş olduğundan emin olun.

---

## Adımlar

### 1. Çalışma Dizinini ve Uygulama Kaynak Dosyalarını Hazırlayın

Standart laboratuvar çalışma dizininizi oluşturun ve içine geçin:

```bash
mkdir -p ~/labs/LAB-DOC-03/src
cd ~/labs/LAB-DOC-03
```

Eğer laboratuvar paketini indirdiyseniz başlangıç dosyalarını kopyalayabilirsiniz:

```bash
cp -a starter/. . 2>/dev/null || true
```

Veya uygulama dosyalarını doğrudan oluşturun:

```bash
cat <<'EOF' > src/app.py
from fastapi import FastAPI
import uvicorn
import os

app = FastAPI(title="DevOps Demo API", version="1.0.0")

@app.get("/")
def read_root():
    return {
        "status": "healthy",
        "service": "order-api",
        "environment": os.getenv("APP_ENV", "production")
    }

@app.get("/healthz")
def health_check():
    return {"status": "UP"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app:app", host="0.0.0.0", port=port, log_level="info")
EOF
```

Bağımlılık dosyasını oluşturun:

```bash
cat <<'EOF' > src/requirements.txt
fastapi==0.110.0
uvicorn==0.28.0
EOF
```

Gereksiz dosyaların imaja girmesini engelleyen `.dockerignore` dosyasını tanımlayın:

```bash
cat <<'EOF' > .dockerignore
__pycache__
*.pyc
*.pyo
*.pyd
.git
.gitignore
.env
.pytest_cache
EOF
```

---

### 2. Optimize Edilmiş Dockerfile Dosyasını Yazın

Layer cache avantajından yararlanmak için önce `requirements.txt` dosyasını kopyalayıp bağımlılıkları kurun, ardından uygulama kodlarını kopyalayın:

```bash
cat <<'EOF' > Dockerfile
FROM python:3.11-alpine

WORKDIR /app

# 1. Aşama: Bağımlılıkları kur (Layer Caching)
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Aşama: Uygulama kodlarını kopyala
COPY src/ .

EXPOSE 8000

CMD ["python", "app.py"]
EOF
```

---

### 3. İmajı Derleyin ve Katmanlarını İnceleyin

İmajı `devops-demo-api:slim` etiketiyle derleyin:

```bash
docker build -t devops-demo-api:slim .
```

Katman yapısını ve her katmanın diskteki boyutunu inceleyin:

```bash
docker history devops-demo-api:slim
```

---

### 4. Konteyneri Başlatın ve API'yi Test Edin

```bash
docker run -d --name demo-api-container -p 8000:8000 devops-demo-api:slim
```

Konteyner durumunu ve sağlık ucunu test edin:

```bash
docker ps --filter name=demo-api-container
curl http://localhost:8000/
curl http://localhost:8000/healthz
```

Beklenen yanıt: `{"status":"UP"}`

---

## 💡 Docker İmajları ve Optimizasyon İnteraktif Pratik Alıştırmaları

#### Soru 1: Docker İmajını Yeni Bir Tag ile Etiketleme
> **Görev:** `devops-demo-api:slim` imajını `devops-demo-api:v1.0.0` ve `devops-demo-api:latest` olarak yeniden etiketleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker tag devops-demo-api:slim devops-demo-api:v1.0.0
    docker tag devops-demo-api:slim devops-demo-api:latest
    docker image ls 'devops-demo-api'
    ```

---

#### Soru 2: Layer Caching Etkisini Gözlemleme
> **Görev:** `src/app.py` dosyasında küçük bir değişiklik yapıp imajı tekrar derleyin. `pip install` adımının `CACHED` olarak geçip geçmediğini inceleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    echo "# Test comment" >> src/app.py
    docker build -t devops-demo-api:slim .
    # Çıktıda 'CACHED' ibaresini göreceksiniz. Bağımlılıklar değişmediği için tekrar internetten indirilmez!
    ```

---

#### Soru 3: İmajı `.tar` Arşivi Olarak Kaydetme (Save & Load)
> **Görev:** `devops-demo-api:slim` imajını `demo-api.tar` olarak diske kaydedin ve ardından yerel imajı silip dosyadan geri yükleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker save -o demo-api.tar devops-demo-api:slim
    ls -lh demo-api.tar
    docker rmi devops-demo-api:slim
    docker load -i demo-api.tar
    ```

---

## Beklenen Sonuç

```json
{"status":"healthy","service":"order-api","environment":"production"}
```

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Sorun Giderme

- **Port Çakışması:** `8000` portu doluysa `docker ps --filter publish=8000` ile çakışan konteyneri durdurun.
- **Modül Bulunamadı Hatası:** `requirements.txt` dosyasındaki paket isimlerini ve `pip install` adımını kontrol edin.
- **Log İnceleme:** `docker logs demo-api-container` komutuyla FastAPI loglarını görüntüleyin.

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak

- [Hakan Bayraktar — flask-monitoring Repository](https://github.com/hakanbayraktar/flask-monitoring)
- [Hakan Bayraktar — Docker Commands Cheat Sheet with Examples](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f)

