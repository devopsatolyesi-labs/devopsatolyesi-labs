# LAB-DOC-13 — Production-Ready Docker Compose Mimarisi ve Desenleri

## Metadata

- **Seviye:** ADVANCED
- **Süre:** 60 dakika
- **Profil:** `docker`
- **Port:** `8080`

## Amaç

Bu labın amacı, Docker Compose kullanarak kurumsal düzeyde **Production-Ready** konteyner orkestrasyon modellerini uygulamalı olarak hayata geçirmektir:

- **Çevre İzolasyonu (Multi-File Compose):** Geliştirme (`compose.override.yaml`) ve canlı (`compose.prod.yaml`) ortamlarını tek bir temel (`compose.yaml`) üzerinde DRY (Don't Repeat Yourself) prensibiyle birleştirmek.
- **Yeniden Kullanılabilir Bloklar (YAML Anchors & Extensions):** `x-logging`, `x-app-defaults` ve `<<: *anchor` sentaksı ile yüzlerce satırlık tekrarı önlemek.
- **Ağ Güvenliği (Dual Isolated Networks):** Dış dünyaya açık `gateway_net` ile sadece dahili servislerin konuştuğu `data_net` ağlarını birbirinden tamamen izole etmek.
- **Servis Sağlığı ve Bağımlılık Zinciri:** `healthcheck` ve `depends_on: condition: service_healthy` ile veritabanı veya kuyruk hazır olmadan uygulamanın başlamasını engellemek.
- **Kaynak Kısıtlama ve Log Rotasyonu:** `deploy.resources.limits` ile CPU/RAM sınırları koymak; logların diski doldurmaması için `json-file` rotasyonu tanımlamak.
- **İsteğe Bağlı Servis Profilleri (Profiles):** `--profile worker` ve `--profile monitoring` ile isteğe bağlı alt servisleri yönetmek.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ve Docker Compose v2 ortamınızın kurulu olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine ve Compose Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

Hızlı sistem ön kontrolü:

```bash
docker compose version
docker info | grep -E "Server Version|Operating System"
```

---

## Mimari ve Ağ İzolasyon Modeli

```text
                        [ Dış Dünya / İstemci ]
                                   | (Port 8080)
                                   v
+-------------------------------------------------------------------------+
|                              NGINX Gateway                              |
+-------------------------------------------------------------------------+
       |                                                    |
   (gateway_net: 172.28.0.0/16)                             |
       v                                                    |
+------------------------------+                            |
|        FastAPI Core          |                            |
+------------------------------+                            |
       |                                                    |
   (data_net: 172.29.0.0/16)                                |
       +--------------------------------+                   |
       |                                |                   |
       v                                v                   v
+----------------+              +---------------+   +-------------------+
|  PostgreSQL 16 |              |   Redis 7     |   | Background Worker |
| (5432 - Gizli) |              | (6379 - Gizli)|   | (Profile: worker) |
+----------------+              +---------------+   +-------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş ve Ortam Değişkenleri

```bash
mkdir -p ~/labs/LAB-DOC-13
cd ~/labs/LAB-DOC-13
```

ZIP indirdiyseniz `unzip LAB-DOC-13.zip && cd LAB-DOC-13` komutunu çalıştırın veya dosyaları oluşturun.

Ortam değişkenleri dosyasını hazırlayın ve dosya izinlerini kısıtlayın:

```bash
cp .env.example .env
chmod 600 .env
```

---

### Adım 2: Compose Dosyalarının ve YAML Uzantılarının İncelenmesi

Temel `compose.yaml` dosyasındaki YAML Anchors ve Extensions yapısını inceleyin:

```bash
cat compose.yaml
```

Önemli tasarım desenleri:
1. **`x-logging`:** Tüm servislere tek satırda log limiti (`max-size: "10m"`, `max-file: "3"`) uygular.
2. **`x-app-defaults`:** Ortak ortam değişkenlerini ve restart politikalarını tanımlar.
3. **`networks`:**
   - `gateway_net`: Nginx ve API arasındaki HTTP trafiğini taşır.
   - `data_net`: API, Worker, Postgres ve Redis arasındaki veri trafiğini izole eder (`internal: true`).

---

### Adım 3: Birleştirilmiş (Rendered) Yapılandırmayı Doğrulama

Production ortamı için `compose.yaml` ve `compose.prod.yaml` dosyalarını birleştirerek nihai çıktıyı test edin:

```bash
# Sentaks ve değişken doğrulaması
docker compose --env-file .env -f compose.yaml -f compose.prod.yaml config --quiet

# Birleştirilmiş tam konfigürasyonu görüntüleyin
docker compose --env-file .env -f compose.yaml -f compose.prod.yaml config
```

---

### Adım 4: Production Stack'i Başlatma ve Sağlık Kontrolü

Tüm servisleri production modunda arka planda başlatın ve tüm servislerin `healthy` durumuna gelmesini bekleyin:

```bash
docker compose -p lab-doc-13 --env-file .env   -f compose.yaml -f compose.prod.yaml up -d --build --wait
```

Servis durumlarını ve port izolasyonunu kontrol edin:

```bash
docker compose -p lab-doc-13 --env-file .env   -f compose.yaml -f compose.prod.yaml ps
```

> [!NOTE]
> Postgres (`5432`) ve Redis (`6379`) portları dışarıya (host) açık olmamalı; sadece Nginx (`8080`) erişilebilir olmalıdır.

---

### Adım 5: Sağlık Uç Noktası (Healthz) Testi

```bash
curl -i http://localhost:8080/healthz
```

Beklenen HTTP 200 JSON Yanıtı:
```json
{
  "status": "HEALTHY",
  "database": "CONNECTED",
  "cache": "CONNECTED"
}
```

---

### Adım 6: İsteğe Bağlı Profilleri (Profiles) Çalıştırma

Worker servisi varsayılan olarak başlamaz; sadece `--profile worker` belirtildiğinde devreye girer:

```bash
# Worker profilini inceleyin
docker compose --env-file .env -f compose.yaml --profile worker config --services

# Worker servisini ayağa kaldırın
docker compose -p lab-doc-13 --env-file .env   -f compose.yaml -f compose.prod.yaml --profile worker up -d worker
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

Aşağıdaki soruları yanıtlamaya çalışın; ardından çözümü görmek için kutucuklara tıklayın:

??? question "Soru 1: Docker Compose'da `compose.yaml` ve `compose.override.yaml` dosyaları varsayılan olarak nasıl davranır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `docker compose up` komutunu hiçbir `-f` bayrağı vermeden çalıştırdığınızda, Docker Compose otomatik olarak önce `compose.yaml` (veya `docker-compose.yml`) dosyasını, ardından dizinde varsa `compose.override.yaml` dosyasını okuyup ikisini birleştirir (merge). Bu mekanizma geliştiricilerin yerel portları veya volume bağlamalarını ana dosyayı bozmadan ezmesine olanak tanır. Canlı ortamda ise `-f compose.yaml -f compose.prod.yaml` şeklinde açıkça belirtilir.

??? question "Soru 2: YAML dosyasında `x-logging: &default-logging` ve `<<: *default-logging` sentaksı ne anlama gelir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `x-` ile başlayan alanlar **Docker Compose Extension Fields** olarak adlandırılır ve Compose tarafından doğrudan bir servis olarak algılanmaz. `&default-logging` bir YAML Çapası (Anchor) oluşturur. `<<: *default-logging` (Merge Key) ise bu çapadaki tüm tanımları hedef servisin altına kopyalar. Böylece 10 farklı servise aynı loglama ayarını tek satırda uygulayabilirsiniz.

??? question "Soru 3: Bir veritabanı konteynerinin `ports:` yerine yalnızca internal bir network'e bağlanmasının güvenlik avantajı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Eğer `ports: - "5432:5432"` tanımlanırsa, PostgreSQL doğrudan host makinenin tüm ağ arayüzlerine (0.0.0.0) açılır. Bu da internete açık bir sunucuda veritabanının dışarıdan doğrudan brute-force saldırılarına maruz kalması demektir. Port açılmayıp yalnızca `data_net` ağına bağlandığında, veritabanına YALNIZCA aynı Docker ağına bağlı yetkili API konteyneri erişebilir.

??? question "Soru 4: `depends_on: condition: service_healthy` ile klasik `depends_on:` arasındaki fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Klasik `depends_on:` sadece bağımlı konteynerin süreç olarak başlatılmasını (Process Started) bekler; veritabanının sorgu kabul edip etmediğine bakmaz. Bu durum uygulamanın "Connection Refused" hatasıyla çökmesine yol açabilir. `service_healthy` ise hedef konteynerin `healthcheck` komutu (ör. `pg_isready`) `0` dönene kadar bekler ve uygulamayı ancak veritabanı tamamen hazır olduğunda başlatır.

??? question "Soru 5: `docker compose down` komutuna `-v` parametresi eklenmezse Persistent Volume verileri silinir mi?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Hayır, silinmez! `docker compose down` yalnızca konteynerleri ve ağları siler; `volumes:` altında tanımlanan Named Volume'lar korunur. Veritabanını tamamen sıfırlamak ve verileri silmek için `docker compose down -v` komutunu çalıştırmanız gerekir.

---

## Sorun Giderme

- **Veritabanı Parola Hatası:** `.env` dosyasındaki `POSTGRES_USER`, `POSTGRES_PASSWORD` ve `POSTGRES_DB` değişkenlerinin eksiksiz olduğunu doğrulayın.
- **Port Meşgul:** 8080 portu meşgulse `docker ps` veya `lsof -i :8080` ile kontrol edin.
- **Servis Sağlıksız:** Belirli bir servisin loglarını `docker compose -p lab-doc-13 logs <servis_adi>` ile inceleyin.

---

## Kaynak ve Referanslar

Bu lab, Production Docker Compose Reference Architecture ve Docker Best Practices kılavuzlarından uyarlanmıştır.
