# LAB-DOC-05 — Ortam Değişkenleri, .env ve Konfigürasyon Yönetimi

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 35 dakika | `docker` | `3000` |

[LAB-DOC-05.zip](/downloads/LAB-DOC-05.zip)


## Amaç

- 12-Factor App metodolojisine uygun olarak konfigürasyonu kaynak koddan ayırmak.
- `docker run -e` ile dinamik ortam değişkeni (environment variable) enjeksiyonu yapmak.
- Çoklu ortam değişkenlerini `.env` dosyası ile yönetmek (`--env-file`).
- Ortam değişkenleri arasındaki öncelik hiyerarşisini test etmek.
- Hassas şifrelerin (secrets) imaj içine hardcode edilmesinin getirdiği güvenlik risklerini ve güvenli çalışma pratiklerini kavramak.

---

## Ön Koşullar

- Docker Engine ortamının hazır olması.
- `3000` portunun boş olması.

---

## Konfigürasyon Modeli

```text
[ Geliştirici Ortamı ]     [ Test / QA ]           [ Canlı / Production ]
  .env.development           .env.staging            .env.production
  DEBUG=true                 DEBUG=false             DEBUG=false
  PORT=3000                  PORT=3000               PORT=3000
  DB_HOST=localhost          DB_HOST=test-db         DB_HOST=prod-cluster.internal
         |                          |                       |
         +--------------------------+-----------------------+
                                    |
                    docker run --env-file <env_file>
                                    v
                 +--------------------------------------+
                 | AYNI DOCKER İMAJI (TEK BİR ARTIFACT) |
                 | - Kod değişmez, konfigürasyon değişir|
                 +--------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-05
cd ~/labs/LAB-DOC-05
```

---

### Adım 2: Tekil Ortam Değişkeni Enjeksiyonu (`-e`)

Konteynere `-e` bayrağı ile doğrudan değişken aktarın ve `env` komutu ile inceleyin:

```bash
docker run --rm   -e APP_NAME="DevOps Portal"   -e APP_ENV="production"   -e LOG_LEVEL="info"   alpine env
```

Çıktıda tanımladığınız değişkenlerin konteyner işletim sistemine aktarıldığını doğrulayın.

---

### Adım 3: `.env` Dosyası Hazırlama ve `--env-file` Kullanımı

Büyük projelerde onlarca ortam değişkeni tek tek `-e` ile verilmez; konfigürasyon dosyalarında tutulur:

```bash
cat <<'EOF' > .env.app
APP_NAME=OrderService
APP_PORT=3000
DB_HOST=postgres.internal
DB_USER=order_admin
FEATURE_PAYMENT_V2=enabled
CACHE_TTL=3600
EOF
```

Dosyayı konteynere aktarın:

```bash
docker run --rm --env-file .env.app alpine env | grep -E "APP_|DB_|FEATURE_|CACHE_"
```

Tüm değişkenlerin eksiksiz yüklendiğini görün.

---

### Adım 4: Değişken Öncelik Hiyerarşisi (Precedence)

Aynı değişken hem `--env-file` içinde hem de komut satırında `-e` ile verilirse ne olur?

```bash
# .env.app içinde FEATURE_PAYMENT_V2=enabled olarak tanımlıydı.
# Şimdi komut satırından 'disabled' olarak ezelim:
docker run --rm   --env-file .env.app   -e FEATURE_PAYMENT_V2=disabled   alpine env | grep FEATURE_PAYMENT_V2
```

> **Kritik Kural:** Komut satırındaki `-e` bayrağı, `--env-file` dosyasındaki değeri daima **GEÇERSİZ KILAR (Overrules)**. Bu durum acil durum yamalarında veya CI/CD boru hatlarında büyük esneklik sağlar.

---

### Adım 5: Konfigürasyonu Okuyan Örnek Node.js Uygulaması

Basit bir Node.js servisi yazıp değişkenleri HTTP üzerinden sunalım:

```bash
cat <<'EOF' > server.js
const http = require('http');

const port = process.env.APP_PORT || 3000;
const appName = process.env.APP_NAME || 'DefaultApp';
const dbHost = process.env.DB_HOST || 'localhost';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    application: appName,
    port: port,
    database_host: dbHost,
    runtime: 'Node.js Container',
    timestamp: new Date().toISOString()
  }));
});

server.listen(port, '0.0.0.0', () => {
  console.log(`${appName} listening on port ${port}`);
});
EOF

cat <<'EOF' > Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
EOF
```

İmajı derleyin ve `.env.app` dosyasıyla başlatın:

```bash
docker build -t lab-doc-05-env-demo:v1 .

docker run -d   --name env-api   -p 3000:3000   --env-file .env.app   lab-doc-05-env-demo:v1
```

HTTP servisini test edin:

```bash
curl -s http://localhost:3000
```

JSON yanıtında `application: "OrderService"` ve `database_host: "postgres.internal"` değerlerinin göründüğünü doğrulayın!

---

## Doğal Doğrulama ve Beklenen Sonuç

- `curl http://localhost:3000` komutu `.env.app` dosyasından okunan `OrderService` yapılandırmasını JSON olarak döner.

---
