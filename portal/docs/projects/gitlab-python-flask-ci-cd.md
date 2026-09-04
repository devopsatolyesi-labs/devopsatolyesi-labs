# Proje — GitLab CI/CD ile Python Flask Mikroservis Teslimat Hattı

## Metadata
- **Seviye:** PRODUCTION PRACTITIONER
- **Önerilen Gün:** Gün 3 / Gün 4
- **Tahmini Süre:** 45 dk
- **Gerekli Ortam:** Öğrenci Ubuntu Sunucusu (`Docker`, `Git`, `Python3 / pip` kurulu)
- **GitLab URL:** `https://gitlab.devopsatolyesi.com/devops-atolyesi/projects/python-flask`
- **Çalışma Deposu:** `devops-atolyesi/projects/python-flask`

---

## 1. Proje Senaryosu
Kurumsal mikroservis mimarilerinde uygulanan üretim standardı, Jenkins veya GitLab fark etmeksizin değişmez teslimat ilkelerine dayanır:
1. **İzole Test:** Kod bağımlılıkları ana makineye kurulmaz; konteyner içinde `pytest` ile test edilir.
2. **Konteyner Sertleştirme (Hardening):** Üretim imajında derleme araçları yer almaz; uygulama root yetkisi olmayan (`non-root UID 10001`) bir kullanıcıyla çalıştırılır.
3. **Otomatik Güvenlik Kapısı (Security Gate):** İmaj üretim ortamına veya registry'ye gönderilmeden önce **Trivy** ile taranır.
4. **Dağıtım ve Duman Testi (Smoke Test):** Servis ayağa kaldırılır, `/health` uç noktası HTTP 200 dönene kadar doğrulanır.
5. **Kaynak Temizliği:** Test tamamlandıktan sonra CI/CD sunucusunda bellek sızıntısı veya atık konteyner kalmaması için `after_script` ile çalışma ortamı temizlenir.

Bu projede, kendi Ubuntu sunucunuzda sıfırdan kurumsal bir Python Flask mikroservisi inşa edecek ve GitLab CI üzerinde uçtan uca çalıştıracaksınız.

---

## 2. Pipeline Mimarisi

![GitLab Python Flask Pipeline Architecture](images/gitlab-python-flask-pipeline.svg)

---

## 3. Öğrenci Ubuntu Sunucusunda Adım Adım Kurulum

### Adım 1: Ubuntu Terminalinde Çalışma Dizinini Hazırlama

Kendi Ubuntu sunucunuzda proje klasör yapısını oluşturun:

```bash
mkdir -p ~/devops-projects/gitlab-python-flask/app
mkdir -p ~/devops-projects/gitlab-python-flask/tests
cd ~/devops-projects/gitlab-python-flask
```

---

### Adım 2: Flask Mikroservis Kodlarını Oluşturma

Servis mantığını ve `/health` uç noktasını barındıran `app/main.py` dosyasını oluşturun:

```bash
cat << 'EOF' > app/main.py
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def root():
    return jsonify({
        "service": "python-flask-production-api",
        "environment": os.getenv("APP_ENV", "production"),
        "status": "running"
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "code": 200,
        "database": "connected"
    }), 200

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8080))
    app.run(host='0.0.0.0', port=port)
EOF
```

Üretim ve test bağımlılıklarını belirten `requirements.txt` dosyasını oluşturun:

```bash
cat << 'EOF' > requirements.txt
Flask==3.1.0
gunicorn==23.0.0
pytest==8.3.4
EOF
```

---

### Adım 3: Pytest Birim Testlerini Oluşturma

Uygulamanın `/` ve `/health` rotalarını doğrulayan test dosyasını `tests/test_app.py` oluşturun:

```bash
cat << 'EOF' > tests/test_app.py
import pytest
from app.main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_root_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["status"] == "running"

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["status"] == "healthy"
EOF
```

---

### Adım 4: Çok Aşamalı (Multi-Stage) Sertleştirilmiş Dockerfile

Üretim standartlarında, derleyici ve test katmanlarını çalışma zamanından ayıran `Dockerfile` dosyasını hazırlayın:

```bash
cat << 'EOF' > Dockerfile
# --- Stage 1: Test & Dependencies ---
FROM python:3.11-slim AS base
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
COPY tests/ ./tests/
ENV PYTHONPATH=/app

# Test target
FROM base AS test
RUN python -m pytest tests/

# --- Stage 2: Hardened Runtime ---
FROM python:3.11-slim AS runtime
WORKDIR /app

# Non-root kısıtlı kullanıcı oluştur
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/false appuser

COPY requirements.txt .
RUN pip install --no-cache-dir Flask==3.1.0 gunicorn==23.0.0

COPY app/ ./app/

USER 10001:10001

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app.main:app"]
EOF
```

---

### Adım 5: GitLab CI Pipeline Dosyasını Oluşturma (`.gitlab-ci.yml`)

Projenin kök dizininde tam kapsamlı `.gitlab-ci.yml` dosyasını oluşturun:

```bash
cat << 'EOF' > .gitlab-ci.yml
stages:
  - test
  - build
  - security
  - deploy

variables:
  IMAGE_NAME: "flask-prod-app"
  TEST_CONTAINER_NAME: "flask-staging-smoke-test"
  HOST_PORT: "8089"

# Stage 1: Konteyner İçinde Pytest Testleri
unit-tests:
  stage: test
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 1: Running Pytest Inside Docker Test Stage ==="
    - docker build --target test -t flask-test:$CI_COMMIT_SHORT_SHA .
    - echo "SUCCESS: All Unit Tests Passed."
  after_script:
    - docker rmi -f flask-test:$CI_COMMIT_SHORT_SHA || true

# Stage 2: Üretim İmajını Derleme
docker-build-hardened:
  stage: build
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 2: Building Production Hardened Image (UID 10001) ==="
    - docker build --target runtime -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA .
    - docker images | grep $IMAGE_NAME

# Stage 3: Trivy Güvenlik Kapısı
trivy-cve-audit:
  stage: security
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 3: Scanning Production Image with Trivy ==="
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.74.0 image --severity CRITICAL --no-progress --exit-code 1 $IMAGE_NAME:$CI_COMMIT_SHORT_SHA
    - echo "SUCCESS: Quality Gate Passed. Zero critical CVEs found."

# Stage 4: Dağıtım, Duman Testi ve Temizlik
deploy-and-smoke-test:
  stage: deploy
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 4: Deploying Container to Staging Port $HOST_PORT ==="
    - docker run -d --name $TEST_CONTAINER_NAME -p $HOST_PORT:8080 $IMAGE_NAME:$CI_COMMIT_SHORT_SHA
    - sleep 4
    - echo "=== Running Smoke Test against /health ==="
    - docker run --rm --net=host curlimages/curl:8.7.1 -fsS http://localhost:$HOST_PORT/health
    - echo "SUCCESS: Staging Deployment Healthy (HTTP 200)."
  after_script:
    - echo "=== Teardown: Stopping and Removing Test Container ==="
    - docker rm -f $TEST_CONTAINER_NAME || true
    - docker rmi -f $IMAGE_NAME:$CI_COMMIT_SHORT_SHA || true
EOF
```

---

### Adım 6: Git İle Depoyu Başlatma ve GitLab'e Push Etme

Ubuntu terminalinizden dosyaları commit edip GitLab'e push edin:

```bash
git init
git config user.name "DevOps Student"
git config user.email "student@devopsatolyesi.com"
git branch -M main

git add .
git commit -m "feat: complete hardened python flask pipeline with smoke test"

# GitLab remote adresini bağlayın
git remote add origin https://gitlab.devopsatolyesi.com/devops-atolyesi/projects/python-flask.git

# GitLab'e push edin (Kullanıcı: devops / Parola: Eğitim şifreniz)
git push -u origin main --force
```

---

### Adım 7: Pipeline Sonuçlarını İnceleme ve Kaynak Kontrolü

1. Tarayıcınızda `https://gitlab.devopsatolyesi.com` adresini açın.
2. `devops-atolyesi/projects/python-flask` projesine gidin.
3. Sol menüden **Build -> Pipelines** yolunu izleyin.
4. 4 aşamanın tamamının (`test`, `build`, `security`, `deploy`) **Passed** olduğunu doğrulayın.
5. `deploy-and-smoke-test` Job loglarında `/health` uç noktasından gelen `{"code": 200, "database": "connected", "status": "healthy"}` yanıtını inceleyin.
6. Sunucunuzda `docker ps` komutunu çalıştırarak hiçbir atık konteynerin kalmadığını ve RAM'in temizlendiğini teyit edin.
