# LAB-DOC-04 — Multi-Stage Build ve Non-Root Konteyner Güvenliği

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-04.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-04.zip && cd LAB-DOC-04`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-04
cd ~/labs/LAB-DOC-04
```

### `starter/.dockerignore`

```bash
mkdir -p "$(dirname -- starter/.dockerignore)"
cat > starter/.dockerignore <<'LAB_FILE_EOF_1'
node_modules
npm-debug.log
.git
.gitignore
README.md
Dockerfile
LAB_FILE_EOF_1
```

### `starter/Dockerfile`

```bash
mkdir -p "$(dirname -- starter/Dockerfile)"
cat > starter/Dockerfile <<'LAB_FILE_EOF_2'
# ==========================================
# LAB-DOC-04: Multi-Stage & Non-Root Hardening
# ==========================================

# AŞAMA 1: Builder Aşaması
# TODO: node:20-alpine imajını 'builder' adıyla taban alın
# FROM node:20-alpine AS builder

# TODO: Çalışma dizinini /build yapın
# WORKDIR /build

# TODO: Bağımlılık dosyalarını kopyalayın ve npm install çalıştırın
# COPY package*.json ./
# RUN npm ci --only=production

# TODO: Uygulama kaynak kodlarını kopyalayın
# COPY server.js ./


# AŞAMA 2: Runtime (Production) Aşaması
# TODO: Minimal ve güvenli node:20-alpine imajını taban alın
# FROM node:20-alpine

# TODO: Güvenlik için UID ve GID 10001 olan non-root 'appuser' kullanıcısını oluşturun
# RUN addgroup -S -g 10001 appgroup && adduser -S -u 10001 -G appgroup appuser

# TODO: Çalışma dizinini /app yapın ve sahipliğini appuser'a verin
# WORKDIR /app

# TODO: Builder aşamasından YALNIZCA gerekli dosyaları (node_modules, package.json, server.js) kopyalayın
# COPY --from=builder --chown=10001:10001 /build/node_modules ./node_modules
# COPY --from=builder --chown=10001:10001 /build/package.json ./package.json
# COPY --from=builder --chown=10001:10001 /build/server.js ./server.js

# TODO: Konteyneri root olmayan 10001 kullanıcısına geçirin
# USER 10001

# TODO: Port 3000'i tanımlayın ve CMD ile sunucuyu başlatın
# EXPOSE 3000
# CMD ["node", "server.js"]
LAB_FILE_EOF_2
```

### `starter/package.json`

```bash
mkdir -p "$(dirname -- starter/package.json)"
cat > starter/package.json <<'LAB_FILE_EOF_3'
{
  "name": "secure-node-api",
  "version": "1.0.0",
  "description": "Multi-stage hardened Node.js microservice",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
LAB_FILE_EOF_3
```

### `starter/server.js`

```bash
mkdir -p "$(dirname -- starter/server.js)"
cat > starter/server.js <<'LAB_FILE_EOF_4'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Production Microservice Hardened & Secure',
    user: process.getuid ? process.getuid() : 'unknown',
    timestamp: new Date().toISOString()
  });
});

app.get('/healthz', (req, res) => {
  res.status(200).send('OK');
});

app.listen(PORT, '0.0.0.0', () => {
  console.log();
});
LAB_FILE_EOF_4
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_5'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-04] Temizleniyor..."
docker stop test-doc-04 2>/dev/null || true
docker rm -f test-doc-04 2>/dev/null || true
docker rmi -f lab-doc-04-hardened:latest 2>/dev/null || true
echo "[BİLGİ] LAB-DOC-04 kaynakları temizlendi."
LAB_FILE_EOF_5
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_6'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-04] Sıfırlanıyor..."
docker stop test-doc-04 2>/dev/null || true
docker rm -f test-doc-04 2>/dev/null || true
docker rmi -f lab-doc-04-hardened:latest 2>/dev/null || true
cp -a starter/. .
echo "[BİLGİ] LAB-DOC-04 başlangıç durumuna sıfırlandı."
LAB_FILE_EOF_6
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_7'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-04] Doğrulama Başlatılıyor: Multi-Stage Build & Non-Root Güvenliği..."

if [[ ! -f Dockerfile ]]; then
  echo "[HATA] Dockerfile bulunamadı! Lütfen ~/labs/LAB-DOC-04 dizininde çalıştırın." >&2
  exit 1
fi

stage_count=
if [[ "" -lt 2 ]]; then
  echo "[HATA] Dockerfile en az 2 aşama (Multi-Stage) içermelidir. Tespit edilen: " >&2
  exit 1
fi

echo "[1/3] İmaj derleniyor: lab-doc-04-hardened:latest..."
docker build -t lab-doc-04-hardened:latest . >/dev/null

echo "[2/3] Konteyner kullanıcı yetkileri (Non-Root) kontrol ediliyor..."
configured_user=
runtime_user=

if [[ "" != *"10001"* || "" != "10001" ]]; then
  echo "[HATA] Beklenen UID: 10001. Tespit edilen Config.User: '', Runtime UID: ''" >&2
  exit 1
fi

echo "[3/3] Konteyner çalışma testi ve HTTP yanıtı kontrol ediliyor..."
container_id=
sleep 2

response=
docker stop test-doc-04 >/dev/null && docker rm test-doc-04 >/dev/null

if [[ "" == *"Production Microservice"* ]]; then
  echo "[BAŞARILI] Multi-stage build ve Non-Root UID 10001 doğrulaması eksiksiz geçti!"
  exit 0
else
  echo "[HATA] Beklenen 'Production Microservice' yanıtı alınamadı. Alınan: " >&2
  exit 1
fi
LAB_FILE_EOF_7
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

Bu labın amacı, modern DevOps standartlarında **Multi-Stage Docker Build** mimarisini ve **Non-Root Kullanıcı Güvenliğini (Least Privilege)** uygulamalı olarak öğrenmektir:

- Geliştirme/derleme araçlarını (SDK, build-cache, compiler) üretim imajından tamamen izole etmek.
- İmaj boyutunu ~1 GB seviyesinden ~50 MB seviyesine düşürerek ağ transferini ve saldırı yüzeyini minimize etmek.
- Konteynerlerin `root (UID 0)` yerine kısıtlı bir kullanıcı (`UID 10001`) ile çalışmasını sağlayarak Container Escape açıklarına karşı sistemi korumak.
- Katman önbellekleme (Layer Caching) ile derleme sürelerini optimize etmek.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ortamınızın hazır olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine ve Compose Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

Hızlı sistem ön kontrolü:

```bash
docker --version
docker ps
```

---

## Mimari ve Güvenlik Modeli

```text
+-----------------------------------------------------------------------+
| AŞAMA 1: Builder (node:20-alpine AS builder)                          |
|  - package.json & server.js kopyalanır                                |
|  - npm install ile bağımlılıklar indirilir                            |
|  - İmaj Boyutu: ~200MB - 1GB (Derleme araçları ve geçici dosyalar)    |
+-----------------------------------------------------------------------+
                                   |
         SADECE GEREKLİ RUNTIME DOSYALARI AKTARILIR (COPY --from=builder)
                                   v
+-----------------------------------------------------------------------+
| AŞAMA 2: Production Runtime (node:20-alpine)                          |
|  - Sadece node_modules, package.json ve server.js aktarılır           |
|  - Kısıtlı Kullanıcı Oluşturulur: UID 10001 (appuser)                 |
|  - İmaj Sahipliği Ayarlanır: --chown=10001:10001                      |
|  - Çalışma Kullanıcısı: USER 10001 (Non-Root)                         |
|  - Nihai İmaj Boyutu: ~55 MB                                          |
+-----------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-04
cd ~/labs/LAB-DOC-04
```

ZIP indirdiyseniz `unzip LAB-DOC-04.zip && cd LAB-DOC-04` komutunu çalıştırın veya aşağıdaki dosyaları oluşturun.

---

### Adım 2: Başlangıç Dosyalarını İnceleyin

Dizindeki `package.json` ve `server.js` dosyalarını inceleyin:

```bash
cat server.js
```

`server.js`, gelen HTTP isteklerine JSON formatında sunucu durumu ve process'in çalıştığı **UID (User ID)** bilgisini döndürür:

```javascript
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Production Microservice Hardened & Secure',
    user: process.getuid ? process.getuid() : 'unknown'
  });
});
```

---

### Adım 3: Multi-Stage ve Non-Root Dockerfile Oluşturma

`Dockerfile` dosyasını iki aşamalı (Multi-Stage) ve UID 10001 ile çalışacak şekilde oluşturun:

```bash
cat <<'EOF' > Dockerfile
# Aşama 1: Builder (Derleme ve Bağımlılık Aşaması)
FROM node:20-alpine AS builder
WORKDIR /build

COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund

COPY server.js ./

# Aşama 2: Minimal & Güvenli Runtime (Production Aşaması)
FROM node:20-alpine
WORKDIR /app

# Güvenlik gereksinimi: UID 10001 olan kısıtlı kullanıcı oluşturma
RUN addgroup -S -g 10001 appgroup && adduser -S -u 10001 -G appgroup appuser

# Yalnızca gerekli runtime dosyalarını kopyalayın ve sahipliğini appuser'a verin
COPY --from=builder --chown=10001:10001 /build/node_modules ./node_modules
COPY --from=builder --chown=10001:10001 /build/package.json ./package.json
COPY --from=builder --chown=10001:10001 /build/server.js ./server.js

USER 10001
EXPOSE 3000

CMD ["node", "server.js"]
EOF
```

---

### Adım 4: İmajı Derleyin ve Katmanları İnceleyin

```bash
docker build -t lab-doc-04-hardened:latest .
```

Derlenen imajın kullanıcı yapılandırmasını ve boyutunu kontrol edin:

```bash
# İmaj yapılandırmasındaki kullanıcıyı sorgulayın
docker image inspect lab-doc-04-hardened:latest --format '{{.Config.User}}'

# İmaj boyutunu inceleyin
docker images lab-doc-04-hardened:latest
```

---

### Adım 5: Konteyneri Başlatın ve Güvenlik Doğrulaması Yapın

```bash
docker run -d --name secure-api -p 3000:3000 lab-doc-04-hardened:latest
```

Konteynerin çalıştığı kullanıcı kimliğini host ve HTTP API üzerinden doğrulayın:

```bash
# HTTP yanıtını ve dönen UID değerini test edin
curl -s http://localhost:3000/

# Konteyner içindeki süreçlerin UID değerini host üzerinden inceleyin
docker top secure-api
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

Aşağıdaki soruları yanıtlamaya çalışın; ardından çözümü görmek için kutucuklara tıklayın:

??? question "Soru 1: Dockerfile içerisinde neden `USER root` yerine `USER 10001` gibi rastgele yüksek bir UID kullanmalıyız?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Konteyner varsayılan olarak `root (UID 0)` ile çalışırsa, konteyner içindeki bir güvenlik açığı veya Container Escape durumunda saldırgan ana makinenin (host) çekirdeğinde de root yetkilerine sahip olabilir. `USER 10001` (Non-Root) kullanıldığında, saldırgan konteynerden kaçsa bile ana makinede yetkisiz, kısıtlı bir kullanıcı olarak hapsolur. Bu ilke **Least Privilege (En Az Yetki)** olarak adlandırılır.

??? question "Soru 2: Multi-stage build kullanırken `COPY --from=builder --chown=10001:10001` parametresini belirtmezsek ne olur?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Varsayılan olarak Docker, dosyaları `root:root (UID 0)` sahipliğiyle kopyalar. Eğer runtime aşamasında `USER 10001` kullanırsanız ve uygulamanız çalışma anında bu dosyalara yazma gereksinimi duyarsa `EACCES: permission denied` hatası alırsınız. `--chown=10001:10001` dosyaların doğrudan ilgili kullanıcıya ait olmasını sağlar.

??? question "Soru 3: Bir konteyner imajının belirli bir derleme aşamasını (örneğin sadece builder) debug amacıyla nasıl derleyebiliriz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Docker BuildKit'in `--target` parametresini kullanabilirsiniz:
        ```bash
        docker build --target builder -t my-debug-app:dev .
        ```
        Bu komut ikinci runtime aşamasını çalıştırmaz; sadece `AS builder` aşamasını derleyerek geliştiricilerin derleme ortamını interaktif olarak test etmesine olanak tanır.

??? question "Soru 4: Node.js uygulamalarında neden `COPY package*.json ./` komutu `COPY . .` komutundan önce yazılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        **Docker Layer Caching** mekanizması nedeniyle. `package.json` sık değişmez, ancak kaynak kodlar (`server.js`) sürekli güncellenir. Eğer bağımlılıkları önce kopyalayıp `npm install` çalıştırırsanız, kaynak kodunuzda bir satır değiştirdiğinizde Docker `npm install` katmanını önbellekten (cache) anında çeker ve derleme saniyeler içinde biter.

??? question "Soru 5: Konteynerin runtime kullanıcısını imajı değiştirmeden `docker run` anında geçersiz kılabilir miyiz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Evet, `docker run` komutuna `--user <UID>:<GID>` bayrağı verilerek imajdaki varsayılan kullanıcı ezilebilir:
        ```bash
        docker run --rm --user 10002:10002 lab-doc-04-hardened:latest id
        ```

---

## Doğrulama

Lab adımlarını tamamladıktan sonra otomatik doğrulama aracını çalıştırın:

```bash
bash scripts/validate.sh
```

---

## Sorun Giderme

- **UID Hatası:** `docker image inspect` çıktısında `Config.User` boş görünüyorsa Dockerfile'da `USER 10001` satırının runtime aşamasında yer aldığından emin olun.
- **Dosya Yetki Hatası:** `COPY --from=builder` satırında `--chown=10001:10001` parametresinin bulunduğunu kontrol edin.
- **Port Çakışması:** 3000 portu meşgulse `docker ps` ile eski konteynerleri temizleyin.

---

## Temizlik

Lab ortamındaki geçici konteynerleri ve imajları temizlemek için:

```bash
bash scripts/cleanup.sh
```

---

## Kaynak ve Referanslar

Bu lab, [ci-cd-docker](https://github.com/hakanbayraktar/ci-cd-docker) ve [jenkins-node](https://github.com/hakanbayraktar/jenkins-node) açık kaynak projelerindeki kurumsal Dockerfile hardening standartlarından uyarlanmıştır.
