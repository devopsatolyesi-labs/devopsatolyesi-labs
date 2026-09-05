# LAB-DOC-08 — Dockerfile Katmanları ve BuildKit Cache

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 45 dakika | `docker` | `8080` |

[LAB-DOC-08.zip](/downloads/LAB-DOC-08.zip)


---

## Amaç

- Docker imajlarının katmanlı (UnionFS / overlay2) dosya sistemi mimarisini derinlemesine anlamak.
- Hatalı katman sıralamasının önbellek geçersiz kılma (cache invalidation) maliyetini ölçümlemek.
- Docker BuildKit motorunu aktif ederek paralel derleme ve gelişmiş cache mekanizmalarını kullanmak.
- Paket yöneticisi önbelleklerini derleme aşamasında bağlamak (`--mount=type=cache`).
- Katmanları birleştirerek (chaining `&&`) gereksiz geçici dosyaları temizlemek ve imaj boyutunu optimize etmek.

---

## Ön Koşullar

- Docker Engine 24.0+ kurulu olması.
- `8080` portunun boş olması.

---

## Katman Önbellekleme Mantığı

```text
[ KÖTÜ PRATİK: Cache Kırıcı Sıralama ]
1. FROM node:20-alpine
2. COPY . .                <--- app.js değişince TÜM alt katmanlar cache'ten düşer!
3. RUN npm install         <--- Her kod değişikliğinde tekrar 2-3 dakika npm indirir!

[ İYİ PRATİK: Optimize Sıralama & BuildKit ]
1. FROM node:20-alpine
2. COPY package*.json .    <--- package.json değişmediği sürece alt satır CACHED kalır!
3. RUN npm ci --omit=dev   <--- CACHED (0.1 saniyede geçer)
4. COPY . .                <--- Sadece bu satır ve sonrası çalışır
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-08
cd ~/labs/LAB-DOC-08
```

---

### Adım 2: Test Uygulamasını Hazırlayın

Basit bir Node.js servisi oluşturalım:

```bash
cat <<'EOF' > package.json
{
  "name": "cache-demo",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "lodash": "^4.17.21"
  }
}
EOF

cat <<'EOF' > server.js
const express = require('express');
const _ = require('lodash');
const app = express();

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'BuildKit & Layer Cache Optimized',
    random: _.random(1, 100)
  });
});

app.listen(8080, () => console.log('Listening on 8080'));
EOF
```

---

### Adım 3: Kötü (Anti-Pattern) Dockerfile ile Süre Karşılaştırması

Önce bilerek kötü tasarlanmış bir Dockerfile hazırlayın:

```bash
cat <<'EOF' > Dockerfile.bad
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
EOF
```

İmajı derleyin ve süresini ölçün:

```bash
time docker build -f Dockerfile.bad -t bad-cache:1.0 .
```

Şimdi `server.js` dosyasında küçük bir değişiklik yapıp tekrar derleyin:

```bash
echo "// minor change" >> server.js
time docker build -f Dockerfile.bad -t bad-cache:1.1 .
```

`npm install` katmanının tekrar çalıştığını ve gereksiz zaman harcadığını gözlemleyin.

---

### Adım 4: Optimize Edilmiş ve BuildKit Destekli Dockerfile Hazırlayın

Şimdi katman sıralamasını düzelten ve BuildKit önbellek bağlayıcısını kullanan profesyonel Dockerfile yazalım:

```bash
cat <<'EOF' > Dockerfile.optimized
# syntax=docker/dockerfile:1
FROM node:20-alpine
WORKDIR /app

# Sadece bağımlılık tanımlarını kopyalayın
COPY package*.json ./

# BuildKit cache mount kullanarak npm cache'ini koruyun
RUN --mount=type=cache,target=/root/.npm     npm ci --omit=dev --prefer-offline

# Kaynak kodları en son ekleyin
COPY server.js ./

EXPOSE 8080
CMD ["node", "server.js"]
EOF
```

---

### Adım 5: Optimize İmajı Derleyin ve Cache Hızını Test Edin

BuildKit'i aktif ederek derleyin:

```bash
DOCKER_BUILDKIT=1 docker build -f Dockerfile.optimized -t good-cache:1.0 .
```

Şimdi kaynak kodda tekrar değişiklik yapıp ikinci derlemeyi başlatın:

```bash
echo "// second change" >> server.js
DOCKER_BUILDKIT=1 docker build -f Dockerfile.optimized -t good-cache:1.1 .
```

Çıktıda `CACHED` etiketlerini ve derlemenin **1 saniyenin altında** bittiğini görün!

---

### Adım 6: İmaj Katmanlarını İnceleyin

`docker history` ile katman boyutlarını ve oluşturulan adımları inceleyin:

```bash
docker history good-cache:1.1
```

---

## Doğal Doğrulama

Optimize edilmiş imajı çalıştırıp test edin:

```bash
docker run -d --name cache-test -p 8080:8080 good-cache:1.1
curl -s http://localhost:8080
docker logs cache-test
```

---

## Doğal Doğrulama ve Beklenen Sonuç

- Optimize derlemede `COPY server.js` dışındaki katmanların `CACHED` olarak işaretlenmesi.
- İkinci derlemenin 0.5 - 1.5 saniye arasında tamamlanması.

---
