# LAB-GLB-01 — GitLab CI/CD Temelleri: Stages, Jobs, Artifacts & Registry

## Metadata
- **Seviye:** PRACTITIONER
- **Önerilen Gün:** Gün 3
- **Tahmini Süre:** 45 dk
- **Gerekli Ortam:** Öğrenci Ubuntu Sunucusu (`Docker`, `Git`, `Node.js / npm` kurulu)
- **GitLab URL:** `https://gitlab.devopsatolyesi.com/devops-atolyesi/labs/lab-glb-01-pipeline`
- **Çalışma Deposu:** `devops-atolyesi/labs/lab-glb-01-pipeline`

---

## 1. Lab Senaryosu
Modern yazılım projelerinde kaynak kod yönetimi, issue takibi ve sürekli entegrasyon süreçlerinin tek bir çatı altında birleştirilmesi operasyonel verimliliği artırır. GitLab CI/CD, repoya push edilen her commit ile tetiklenen deklaratif `.gitlab-ci.yml` mimarisiyle çalışır.

Hatalı kurgulanan Artifacts ve Cache yapılandırmaları bağımlılıkların her seferinde baştan indirilmesine veya derleme çıktılarının sonraki aşamalara aktarılamamasına neden olur. Bu çalışmada Node.js mikroservisi için test, Trivy güvenlik taraması, Docker imaj derleme ve canlı dağıtım adımlarını içeren gerçek bir GitLab CI/CD Pipeline'ı kendi Ubuntu sunucunuzda sıfırdan kuracaksınız.

---

## 2. Amaçlar
- GitLab CI/CD sözdizimi (`.gitlab-ci.yml`) ile çok aşamalı (`stages`, `jobs`, `artifacts`, `rules`) bir Pipeline oluşturmak.
- Docker-in-Docker (DinD) ve Trivy ile konteyner ve dosya sistemi güvenlik taramasını otomatize etmek.
- Test, Security, Build ve Deploy aşamalarını uçtan uca yürütmek.
- Dağıtılan servisin `/health` uç noktasını duman testiyle (Smoke Test) doğrulamak.
- `after_script` kullanarak atık konteynerleri ve imajları sunucudan temizlemek.

---

## 3. Pipeline Mimarisi

![LAB-GLB-01 Pipeline Architecture](images/lab-glb-01-pipeline.svg)

---

## 4. Öğrenci Ubuntu Sunucusunda Adım Adım Kurulum

### Adım 1: Ubuntu Terminalinde Çalışma Dizinini Hazırlama

Kendi Ubuntu sunucunuzun terminalinde lab dizinini oluşturun:

```bash
mkdir -p ~/devops-labs/lab-glb-01-pipeline/app
cd ~/devops-labs/lab-glb-01-pipeline
```

---

### Adım 2: Demo Uygulama Kodlarını Oluşturma

Servis giriş noktası olan `app/server.js` dosyasını oluşturun:

```bash
cat << 'EOF' > app/server.js
const http = require('http');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'UP', service: 'gitlab-demo-api' }));
    return;
  }
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ message: 'GitLab CI/CD Driven API', status: 'online' }));
});

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});

module.exports = server;
EOF
```

Servis paket tanımını `app/package.json` oluşturun:

```bash
cat << 'EOF' > app/package.json
{
  "name": "gitlab-demo-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "test": "node test.js",
    "start": "node server.js"
  }
}
EOF
```

Birim testi yürüten `app/test.js` dosyasını oluşturun:

```bash
cat << 'EOF' > app/test.js
const assert = require('assert');
const server = require('./server');

console.log("Running unit tests...");
assert.strictEqual(typeof server, 'object', "Server should be an object");
console.log("ALL TESTS PASSED (1/1)");
server.close();
EOF
```

Konteynerleştirme için `app/Dockerfile` dosyasını oluşturun:

```bash
cat << 'EOF' > app/Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package.json server.js ./

USER node

EXPOSE 3000

CMD ["node", "server.js"]
EOF
```

---

### Adım 3: GitLab CI Pipeline Dosyasını Oluşturma (`.gitlab-ci.yml`)

Proje kök dizininde `.gitlab-ci.yml` dosyasını oluşturun:

```bash
cat << 'EOF' > .gitlab-ci.yml
stages:
  - test
  - security
  - build
  - deploy

variables:
  IMAGE_NAME: "demo-api"
  CONTAINER_NAME: "demo-api-staging"
  HOST_PORT: "3089"

# Stage 1: Birim Testler
unit-tests:
  stage: test
  image: node:20-alpine
  script:
    - echo "=== Stage 1: Running Unit Tests ==="
    - cd app
    - node test.js

# Stage 2: Güvenlik ve CVE Taraması
dependency-scan:
  stage: security
  image:
    name: aquasec/trivy:0.74.0
    entrypoint: [""]
  script:
    - echo "=== Stage 2: Scanning Filesystem with Trivy ==="
    - trivy fs --no-progress --severity HIGH,CRITICAL --exit-code 1 app/

# Stage 3: Docker İmajı Derleme
docker-build:
  stage: build
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 3: Building Docker Image ==="
    - docker build -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA app/
    - docker images | grep $IMAGE_NAME

# Stage 4: Dağıtım, Duman Testi ve Temizlik
deploy-and-smoke:
  stage: deploy
  image: docker:27.5.1-cli
  script:
    - echo "=== Stage 4: Deploying Container on Port $HOST_PORT ==="
    - docker run -d --name $CONTAINER_NAME -p $HOST_PORT:3000 $IMAGE_NAME:$CI_COMMIT_SHORT_SHA
    - sleep 3
    - echo "=== Running Smoke Test against /health ==="
    - docker run --rm --net=host curlimages/curl:8.7.1 -fsS http://localhost:$HOST_PORT/health
    - echo "SUCCESS: Service responded healthy."
  after_script:
    - echo "=== Post Cleanup: Removing temporary container and image ==="
    - docker rm -f $CONTAINER_NAME || true
    - docker rmi -f $IMAGE_NAME:$CI_COMMIT_SHORT_SHA || true
EOF
```

---

### Adım 4: Git İle Depoyu Başlatma ve GitLab'e Push Etme

Ubuntu terminalinizden dosyaları commit edip GitLab'e gönderin:

```bash
git init
git config user.name "DevOps Student"
git config user.email "student@devopsatolyesi.com"
git branch -M main

git add .
git commit -m "feat: setup full gitlab ci pipeline with test, scan, build and deploy"

# GitLab remote adresini tanımlayın
git remote add origin https://gitlab.devopsatolyesi.com/devops-atolyesi/labs/lab-glb-01-pipeline.git

# GitLab'e push edin (Kullanıcı: devops / Parola: Eğitim şifreniz)
git push -u origin main --force
```

---

### Adım 5: Pipeline ve Runner Yürütmesini İnceleme

1. Tarayıcınızda `https://gitlab.devopsatolyesi.com` adresini açın.
2. `devops-atolyesi/labs/lab-glb-01-pipeline` projesine gidin.
3. Sol menüden **Build -> Pipelines** yolunu izleyip en son koşan Pipeline'ı açın.
4. Sırasıyla `unit-tests`, `dependency-scan`, `docker-build` ve `deploy-and-smoke` işlerinin tamamının **yeşil (Passed)** yandığını doğrulayın.
5. Loglarda duman testinin `/health` yanıtını aldığını ve ardından `after_script` ile konteynerin durdurulduğunu inceleyin.
