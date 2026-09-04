# LAB-DOC-19 — Production Docker Compose Desenleri

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 50 dakika | `docker` | `80, 3000` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-19.zip)](/downloads/LAB-DOC-19.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 50 dakika | `docker` | `80`, `3000` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-19.zip)](/downloads/LAB-DOC-19.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Geliştirme (dev) ve üretim (prod) ortamları için dosya birleştirme (`-f docker-compose.yml -f docker-compose.prod.yml`) desenini uygulamak.
- Compose Profilleri (`profiles: ["debug"]`, `profiles: ["monitoring"]`) kullanarak isteğe bağlı servisleri yönetmek.
- Ortam değişkeni yer değiştirme (Environment Variable Substitution `${PORT:-8080}`) kurallarını kullanmak.
- Docker Secrets ile hassas verileri ortam değişkeni yerine dosya tabanlı güvenli mount ile yönetmek.
- Üretim ortamında tekil hata noktalarını önlemek için kaynak limitleri ve healthcheck zinciri tanımlamak.

---

## Ön Koşullar

- Docker Engine ve Compose v2 kurulu olmalıdır.

---

## Çoklu Ortam Compose Mimarisi

```text
[ docker-compose.yml ] (Temel Tanımlar)
  - Servis adları, imajlar, ağlar
          │
          ├── + [ docker-compose.override.yml ] ---> (Geliştirici Ortamı: Hot-reload, açık portlar)
          │
          └── + [ docker-compose.prod.yml ]     ---> (Üretim Ortamı: Kaynak limitleri, secrets, log rotasyonu)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-19
cd ~/labs/LAB-DOC-19
```

---

### Adım 2: Temel `docker-compose.yml` Hazırlayın

```bash
cat <<'EOF' > docker-compose.yml
services:
  api:
    image: node:20-alpine
    working_dir: /app
    command: ["sh", "-c", "echo 'API running with DB user:' $$(cat /run/secrets/db_user 2>/dev/null || echo $$DB_USER) && sleep infinity"]
    environment:
      APP_ENV: ${APP_ENV:-production}
      PORT: ${PORT:-3000}
    networks:
      - app-net

  debug-tool:
    image: alpine:3.19
    profiles: ["debug"]
    command: ["sleep", "infinity"]
    networks:
      - app-net

networks:
  app-net:
EOF
```

---

### Adım 3: Üretim Katmanı `docker-compose.prod.yml` Hazırlayın

```bash
cat <<'EOF' > docker-compose.prod.yml
services:
  api:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    secrets:
      - db_user
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

secrets:
  db_user:
    file: ./secrets/db_user.txt
EOF
```

---

### Adım 4: Gizli Dosyayı (Secret) Oluşturun

```bash
mkdir -p secrets
echo "production_enterprise_user" > secrets/db_user.txt
chmod 600 secrets/db_user.txt
```

---

### Adım 5: Yapılandırmayı Birleştirin ve Doğrulayın (Config Lint)

Docker Compose'un iki dosyayı nasıl harmanladığını inceleyin:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml config
```

Çıktıda hem temel ayarların hem de üretim limitlerinin ve secrets tanımlarının birleştiğini görün.

---

### Adım 6: Üretim Yığınını Ayağa Kaldırın

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

`debug-tool` servisinin profili (`debug`) belirtilmediği için ayağa kalkmadığını doğrulayın:

```bash
docker compose ps
```

Şimdi debug profiliyle birlikte çalıştırın:

```bash
docker compose --profile debug up -d
docker compose ps
```

---

## Doğal Doğrulama

API servisinin Docker Secrets üzerinden şifreyi okuduğunu doğrulayın:

```bash
docker compose logs api | grep "production_enterprise_user" && echo "Secret entegrasyonu BAŞARILI"
```

---

### Adım 7: Temizlik

```bash
docker compose --profile debug down -v
rm -rf secrets
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Docker Compose Profilleri (`profiles:`) hangi senaryolarda hayat kurtarır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Aynı compose dosyasında yer alan fakat her ortamda veya sürekli çalışması gerekmeyen servisler için (örneğin veritabanı migration scriptleri, Swagger API belgelendirme UI'ı, Prometheus/Grafana gibi monitoring araçları veya hata ayıklama araçları) kullanılır. `--profile <isim>` verilmedikçe bu servisler başlatılmaz.

---

## Beklenen Sonuç

- `docker compose config` birleşik geçerli YAML çıktısı verir.
- API konteyneri gizli veriyi `/run/secrets/db_user` üzerinden okur.
