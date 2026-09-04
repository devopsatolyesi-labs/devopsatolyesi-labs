# LAB-DOC-14 — Healthcheck, Restart Policy ve Kaynak Limitleri

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 45 dakika | `docker` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-14.zip)](/downloads/LAB-DOC-14.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 45 dakika | `docker` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-14.zip)](/downloads/LAB-DOC-14.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Dockerfile ve Compose üzerinde `HEALTHCHECK` mekanizmasını uygulamak (`interval`, `timeout`, `retries`, `start_period`).
- `depends_on: { condition: service_healthy }` ile servislerin gerçekten hazır olmasını beklemek.
- Yeniden başlatma politikalarını (`restart: on-failure`, `restart: unless-stopped`) test etmek.
- CPU (`cpus: '0.5'`) ve Bellek (`memory: 256M`) kotaları koyarak aşırı kaynak tüketimini engellemek.
- Bellek sınırını aşan bir uygulamada Linux Out-of-Memory (OOM) Killer davranışını ve `137` çıkış kodunu gözlemlemek.

---

## Ön Koşullar

- Docker Engine ve Docker Compose v2 kurulu olmalıdır.
- `8080` portu boş olmalıdır.

---

## Healthcheck ve Kaynak Kontrol Modeli

```text
+-------------------------------------------------------------+
| HEALTHCHECK DÖNGÜSÜ                                         |
|  - curl -f http://localhost:8080/health || exit 1           |
|  - Periyot: her 5 saniyede bir (interval: 5s)               |
|  - Başlangıç Toleransı: 10s (start_period: 10s)             |
|  - Başarısızlık Eşiği: 3 hata üst üste ---> (unhealthy)     |
+-------------------------------------------------------------+
                               │
            BAĞIMLI SERVİS YALNIZCA HEALTHY İKEN BAŞLAR
            depends_on: { condition: service_healthy }
                               ▼
+-------------------------------------------------------------+
| KAYNAK KISITLAMASI & OOM KORUMASI                           |
|  - cpus: '0.50' (Yarım CPU çekirdeği sınırı)                |
|  - memory: 128M (Maksimum 128 MB RAM)                       |
|  - 128MB aşılırsa: Linux Kernel OOM Killer tetiklenir       |
|    -> Exit Code 137                                         |
+-------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-14
cd ~/labs/LAB-DOC-14
```

---

### Adım 2: Simüle Edilmiş Sağlık ve Bellek Sızıntısı Uygulaması Yazın

```bash
cat <<'EOF' > server.py
import os
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

is_healthy = True

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global is_healthy
        if self.path == "/health":
            if is_healthy:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'{"status":"healthy"}')
            else:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'{"status":"unhealthy"}')
        elif self.path == "/break":
            is_healthy = False
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Service marked unhealthy!')
        elif self.path == "/leak":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Leaking memory until OOM...')
            # Kasıtlı bellek tüketimi
            leak = []
            while True:
                leak.append(' ' * (1024 * 1024)) # Her tur 1MB
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Service Operational')

if __name__ == "__main__":
    server = HTTPServer(('0.0.0.0', 8080), Handler)
    print("Serving on 8080...")
    server.serve_forever()
EOF
```

---

### Adım 3: Healthcheck ve Kaynak Limitli `docker-compose.yml` Hazırlayın

```bash
cat <<'EOF' > docker-compose.yml
services:
  app:
    image: python:3.11-alpine
    container_name: health-app
    working_dir: /app
    volumes:
      - ./server.py:/app/server.py:ro
    command: ["python", "server.py"]
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:8080/health || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 5s
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 128M
    restart: on-failure:5
EOF
```

---

### Adım 4: Konteyneri Başlatın ve Sağlık Durumunu İzleyin

```bash
docker compose up -d
```

Konteynerin sağlık durumunu takip edin:

```bash
docker inspect --format='{{json .State.Health.Status}}' health-app
```

İlk 5 saniye `"starting"`, ardından `"healthy"` çıktısını görün.

---

### Adım 5: Sağlık Kontrolünü Kasıtlı Olarak Bozun

Sağlık durumunu `500 Internal Server Error` döndürecek şekilde tetikleyin:

```bash
curl -s http://localhost:8080/break
```

15 saniye bekleyin (3 deneme x 5s aralık) ve durumu tekrar sorgulayın:

```bash
docker inspect --format='{{json .State.Health.Status}}' health-app
docker ps --filter name=health-app
```

Durumun `unhealthy` olarak işaretlendiğini görün!

---

### Adım 6: OOM Killer ve Exit Code 137 Testi

Şimdi uygulamanın 128MB RAM sınırını aşmasını sağlayalım:

```bash
# Arka planda logları dinlemeye alın
docker compose logs -f app &
LOG_PID=$!

# Bellek tüketim endpoint'ini çağırın
curl -s http://localhost:8080/leak || true

kill $LOG_PID 2>/dev/null || true
```

Konteynerin durumunu ve çıkış kodunu inceleyin:

```bash
docker inspect health-app --format='ExitCode={{.State.ExitCode}} OOMKilled={{.State.OOMKilled}}'
```

Çıktıda `ExitCode=137 OOMKilled=true` göreceksiniz. Linux çekirdeği bellek kotasını aşan konteyneri `SIGKILL (9)` ile imha etmiştir (`128 + 9 = 137`).

---

### Adım 7: Temizlik

```bash
docker compose down
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Neden Dockerfile veya Compose içinde `HEALTHCHECK` tanımlamak sadece `docker ps` çıktısına bakmaktan daha üstündür?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `docker ps` sadece işletim sistemi seviyesinde ana process'in (PID 1) ayakta olup olmadığına bakar. Process kilitlenmiş (deadlock), veritabanı bağlantısı kopmuş veya sonsuz döngüye girmiş olsa bile `docker ps` konteyneri "Up" gösterir. `HEALTHCHECK` ise doğrudan HTTP endpoint'ini veya veritabanı soketini sorgulayarak uygulamanın gerçekten istek karşılayabilir durumda olduğunu garanti eder.

??? question "Soru 2: Çıkış kodunun `137` olması ne anlama gelir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Linux'ta standart çıkış kodu formülü `128 + Sinyal Kodu`dur. `SIGKILL` sinyal kodu `9` olduğundan, `128 + 9 = 137` çıkar. Bu, sürecin normal şekilde kapanmadığını, doğrudan işletim sistemi çekirdeği (genellikle Out-Of-Memory Killer) tarafından zorla sonlandırıldığını kanıtlar.

---

## Beklenen Sonuç

- `docker ps` çıktısında `(healthy)` ve daha sonra `(unhealthy)` ibaresi.
- Bellek taşmasında `ExitCode=137 OOMKilled=true` doğrulaması.
