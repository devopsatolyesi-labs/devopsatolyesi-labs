# LAB-DOC-03 — Python API için Dockerfile, Katman Optimizasyonu ve İmaj Yönetimi

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

## Sorun Giderme

- **Port Çakışması:** `8000` portu doluysa `docker ps --filter publish=8000` ile çakışan konteyneri durdurun.
- **Modül Bulunamadı Hatası:** `requirements.txt` dosyasındaki paket isimlerini ve `pip install` adımını kontrol edin.
- **Log İnceleme:** `docker logs demo-api-container` komutuyla FastAPI loglarını görüntüleyin.
