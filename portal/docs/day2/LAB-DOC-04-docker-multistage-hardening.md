# LAB-DOC-04 — Multi-Stage Build ve Non-Root Konteyner Güvenliği

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `docker` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-04.zip)](/downloads/LAB-DOC-04.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


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

## Sorun Giderme

- **UID Hatası:** `docker image inspect` çıktısında `Config.User` boş görünüyorsa Dockerfile'da `USER 10001` satırının runtime aşamasında yer aldığından emin olun.
- **Dosya Yetki Hatası:** `COPY --from=builder` satırında `--chown=10001:10001` parametresinin bulunduğunu kontrol edin.
- **Port Çakışması:** 3000 portu meşgulse `docker ps` ile eski konteynerleri temizleyin.
