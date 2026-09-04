# Proje — GitLab CI/CD ile DevOps Capstone Teslimat Hattı

## Metadata
- **Seviye:** ADVANCED CAPSTONE
- **Önerilen Gün:** Gün 5
- **Tahmini Süre:** 60 dk
- **Gerekli Ortam:** Öğrenci Ubuntu Sunucusu (`Docker`, `Git`, `Python3` kurulu)
- **GitLab URL:** `https://gitlab.devopsatolyesi.com/devops-atolyesi/projects/devops-capstone`
- **Çalışma Deposu:** `devops-atolyesi/projects/devops-capstone`

---

## 1. Capstone Proje Senaryosu
DevOps Capstone projesi, 5 günlük yoğun eğitimin tüm yetkinliklerini (Linux, Git, Docker, CI/CD, DevSecOps, Smoke Testing, Cleanup) tek bir uçtan uca teslimat hattında birleştirir.

Bir mikroservisin üretim ortamına güvenle taşınabilmesi için geçmesi gereken 5 temel aşama bu pipeline üzerinde modellenmiştir:
1. **Lint Stage:** Kaynak kodun derlenebilirliği ve sözdizimi doğrulanır (`py_compile`).
2. **Test Stage:** Birim testler (`unittest` / `pytest`) çalıştırılır; tek bir test bile başarısız olursa süreç anında kesilir.
3. **Package Stage:** Sertleştirilmiş, minimal üretim konteyneri paketlenir.
4. **Security Gate:** Trivy ile imaj zafiyet denetimi yapılır.
5. **Deploy & Teardown Stage:** Canlı çalışma zamanına deploy edilir, `/health` duman testi ile doğrulanır ve sunucu kaynaklarını korumak için `after_script` ile otomatik temizlenir.

---

## 2. Pipeline Mimarisi

![GitLab DevOps Capstone Pipeline Architecture](images/gitlab-devops-capstone-pipeline.svg)

---

## 3. Öğrenci Ubuntu Sunucusunda Adım Adım Kurulum

### Adım 1: Ubuntu Terminalinde Çalışma Dizinini Hazırlama

Kendi Ubuntu sunucunuzda proje dizinlerini oluşturun:

```bash
mkdir -p ~/devops-projects/gitlab-devops-capstone/src
mkdir -p ~/devops-projects/gitlab-devops-capstone/tests
cd ~/devops-projects/gitlab-devops-capstone
```

---

### Adım 2: Capstone Uygulama Kodlarını Oluşturma

Hafif ve saf Python HTTP sunucusu tabanlı `src/app.py` dosyasını oluşturun:

```bash
cat << 'EOF' > src/app.py
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os

PORT = int(os.environ.get("PORT", 8080))

class CapstoneHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "healthy",
                "service": "devops-capstone",
                "version": "1.0.0"
            }).encode('utf-8'))
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "message": "DevOps Atolyesi Capstone Project - Production Pipeline Active"
            }).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def run():
    server_address = ('0.0.0.0', PORT)
    httpd = HTTPServer(server_address, CapstoneHandler)
    print(f"Capstone service running on port {PORT}...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()
EOF
```

Servis mantığını doğrulayan birim test dosyasını `tests/test_main.py` oluşturun:

```bash
cat << 'EOF' > tests/test_main.py
import unittest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))
from app import CapstoneHandler

class TestCapstone(unittest.TestCase):
    def test_handler_exists(self):
        self.assertTrue(hasattr(CapstoneHandler, 'do_GET'))

    def test_environment_port_default(self):
        port = int(os.environ.get("PORT", 8080))
        self.assertEqual(port, 8080)

if __name__ == '__main__':
    unittest.main()
EOF
```

Güvenli ve minimal Python Alpine `Dockerfile` dosyasını oluşturun:

```bash
cat << 'EOF' > Dockerfile
FROM python:3.11-alpine

WORKDIR /app

# Güvenlik için non-root kullanıcı oluştur
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY src/ /app/src/

USER appuser

EXPOSE 8080

CMD ["python", "src/app.py"]
EOF
```

---

### Adım 3: GitLab CI Pipeline Dosyasını Oluşturma (`.gitlab-ci.yml`)

5 aşamalı eksiksiz Capstone `.gitlab-ci.yml` dosyasını oluşturun:

```bash
cat << 'EOF' > .gitlab-ci.yml
stages:
  - lint
  - test
  - package
  - security
  - deploy

variables:
  APP_NAME: "capstone-delivery-service"
  CONTAINER_NAME: "capstone-staging-test"
  HOST_PORT: "8090"

# Stage 1: Sözdizimi Denetimi
lint-and-validate:
  stage: lint
  image: python:3.11-alpine
  script:
    - echo "=== Stage 1: Syntax Validation ==="
    - python -m py_compile src/app.py
    - echo "SUCCESS: Python syntax valid."

# Stage 2: Birim Testler
run-test-suite:
  stage: test
  image: python:3.11-alpine
  script:
    - echo "=== Stage 2: Running Unit Tests ==="
    - python -m unittest discover -s tests -p "test_*.py"
    - echo "SUCCESS: All unit tests passed."

# Stage 3: Konteyner Paketleme
build-container:
  stage: package
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 3: Packaging Hardened Docker Image ==="
    - docker build -t $APP_NAME:$CI_COMMIT_SHORT_SHA .
    - docker images | grep $APP_NAME

# Stage 4: Trivy Güvenlik Kapısı
trivy-security-gate:
  stage: security
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 4: Running Trivy Security Gate ==="
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.74.0 image --severity CRITICAL --no-progress --exit-code 1 $APP_NAME:$CI_COMMIT_SHORT_SHA
    - echo "SUCCESS: Security gate passed."

# Stage 5: Dağıtım, Duman Testi ve Temizlik
deploy-and-smoke-test:
  stage: deploy
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 5: Deploying to Staging Port $HOST_PORT ==="
    - docker run -d --name $CONTAINER_NAME -p $HOST_PORT:8080 $APP_NAME:$CI_COMMIT_SHORT_SHA
    - sleep 4
    - echo "=== Running Smoke Test against /health ==="
    - docker run --rm --net=host curlimages/curl:8.7.1 -fsS http://localhost:$HOST_PORT/health
    - echo "SUCCESS: Capstone Staging Service verified healthy."
  after_script:
    - echo "=== Post Cleanup: Teardown Test Container ==="
    - docker rm -f $CONTAINER_NAME || true
    - docker rmi -f $APP_NAME:$CI_COMMIT_SHORT_SHA || true
EOF
```

---

### Adım 4: Git İle Depoyu Başlatma ve GitLab'e Push Etme

Ubuntu terminalinizden dosyaları commit edip GitLab'e push edin:

```bash
git init
git config user.name "DevOps Student"
git config user.email "student@devopsatolyesi.com"
git branch -M main

git add .
git commit -m "feat: complete end-to-end devops capstone delivery pipeline"

# GitLab remote adresini bağlayın
git remote add origin https://gitlab.devopsatolyesi.com/devops-atolyesi/projects/devops-capstone.git

# GitLab'e push edin (Kullanıcı: devops / Parola: Eğitim şifreniz)
git push -u origin main --force
```

---

### Adım 5: Capstone Pipeline Başarısını Doğrulama

1. Tarayıcınızda `https://gitlab.devopsatolyesi.com` adresini açın.
2. `devops-atolyesi/projects/devops-capstone` projesine gidin.
3. Sol menüden **Build -> Pipelines** yolunu izleyin.
4. 5 aşamalı (`lint` ➔ `test` ➔ `package` ➔ `security` ➔ `deploy`) hattın tamamının **yeşil (Passed)** yandığını teyit edin.
5. Loglarda `/health` duman testinin başarıyla sonuçlandığını ve `after_script` ile konteynerin temizlendiğini doğrulayın.
