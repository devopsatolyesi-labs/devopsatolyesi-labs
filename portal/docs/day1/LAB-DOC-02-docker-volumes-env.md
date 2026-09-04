# LAB-DOC-02 — Docker Volumes, Ortam Değişkenleri ve Veri Kalıcılığı

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-02.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-02.zip && cd LAB-DOC-02`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-02
cd ~/labs/LAB-DOC-02
```

### `starter/compose.yaml`

```bash
mkdir -p "$(dirname -- starter/compose.yaml)"
cat > starter/compose.yaml <<'LAB_FILE_EOF_1'
# LAB-DOC-02 Starter
services:
  database:
    image: postgres:16-alpine
    # TODO: Add environment variables and named volume persistence
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
docker compose -p lab-doc-02 down -v 2>/dev/null || true
echo "Cleanup completed for LAB-DOC-02."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-DOC-02..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
cp -a "$script_dir/../starter/." .
echo "Workspace reset to starter state for LAB-DOC-02."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-02: Volumes & Environment..."
export LAB_POSTGRES_PASSWORD=${LAB_POSTGRES_PASSWORD:-training-only-password}
project=lab-doc-02
cleanup() {
    docker compose -p "$project" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker compose -p "$project" config --quiet
docker compose -p "$project" up -d --wait
docker compose -p "$project" exec -T database \
    psql -U devops -d training -v ON_ERROR_STOP=1 -c \
    "CREATE TABLE IF NOT EXISTS lab_events(name text); TRUNCATE lab_events; INSERT INTO lab_events VALUES ('volume-ok');" \
    >/dev/null

first_container=$(docker compose -p "$project" ps -q database)
docker compose -p "$project" rm -sf database >/dev/null
docker compose -p "$project" up -d --wait
second_container=$(docker compose -p "$project" ps -q database)
row_count=$(docker compose -p "$project" exec -T database \
    psql -U devops -d training -tAc "SELECT count(*) FROM lab_events WHERE name='volume-ok';")

if [[ "$first_container" == "$second_container" || "$row_count" != "1" ]]; then
    echo "[FAIL] LAB-DOC-02 container recreation or persisted row check failed." >&2
    exit 1
fi
echo "[PASS] LAB-DOC-02 volume persistence verified."
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

- Docker ortam değişkenlerini (`environment`, `.env`) güvenli biçimde yapılandırmak.
- Named Volume kullanarak konteyner silinse bile veritabanı verilerinin kalıcılığını (persistence) sağlamak.
- Bind Mount ile yerel dosya sistemini konteynere bağlamayı kavramak.
- İnteraktif hacim ve ortam değişkeni alıştırmalarını çözmek.

---

## Ön Koşullar

Çalışma ortamınızda Docker ve Docker Compose servislerinin çalıştığından emin olun:

```bash
docker version
docker compose version
```

> Komutlar hata vermeden tamamlanmalıdır. `5432` portunun boş olduğundan emin olun.

---

## Adımlar

### 1. Çalışma Dizinini ve Başlangıç Dosyalarını Hazırlayın

Standart laboratuvar çalışma dizininizi oluşturun ve içine geçin:

```bash
mkdir -p ~/labs/LAB-DOC-02
cd ~/labs/LAB-DOC-02
```

Eğer laboratuvar paketini indirdiyseniz başlangıç dosyalarını kopyalayabilirsiniz:

```bash
cp -a starter/. . 2>/dev/null || true
```

Veya başlangıç `compose.yaml` dosyasını oluşturun:

```bash
cat <<'YAML' > compose.yaml
services:
  database:
    image: postgres:16-alpine
    # TODO: environment, volume, port ve healthcheck alanlarını ekleyin.
YAML
```

---

### 2. Compose Tanımını Tamamlayın

`compose.yaml` dosyasını düzenleyerek PostgreSQL veritabanını, named volume ve healthcheck tanımlarını ekleyin:

```bash
cat <<'YAML' > compose.yaml
services:
  database:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: devops
      POSTGRES_PASSWORD: ${LAB_POSTGRES_PASSWORD:?LAB_POSTGRES_PASSWORD is required}
      POSTGRES_DB: training
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U devops -d training"]
      interval: 2s
      timeout: 2s
      retries: 15

volumes:
  pgdata:
YAML
```

---

### 3. Ortam Değişkenini Tanımlayın ve Yapılandırmayı Doğrulayın

Parolayı doğrudan YAML dosyasına yazmak yerine terminal ortam değişkeni üzerinden sağlayın:

```bash
export LAB_POSTGRES_PASSWORD='training-only-password'
docker compose -p lab-doc-02 config --quiet
```

---

### 4. Veritabanını Başlatın

```bash
docker compose -p lab-doc-02 up -d --wait
docker compose -p lab-doc-02 ps
```

---

### 5. Veritabanına Test Verisi Ekleyin

Konteyner içinde çalışan PostgreSQL'e bağlanarak bir tablo oluşturun ve veri ekleyin:

```bash
docker compose -p lab-doc-02 exec -T database \
  psql -U devops -d training -c \
  "CREATE TABLE IF NOT EXISTS lab_events(name text); INSERT INTO lab_events VALUES ('volume-ok');"
```

Eklenen veriyi kontrol edin:

```bash
docker compose -p lab-doc-02 exec -T database \
  psql -U devops -d training -c "SELECT * FROM lab_events;"
```

---

### 6. Konteyneri Silip Yeniden Oluşturun (Veri Kalıcılığı Testi)

Mevcut konteyneri tamamen kaldırıp sıfırdan yeni bir konteyner başlatın:

```bash
docker compose -p lab-doc-02 rm -sf database
docker compose -p lab-doc-02 up -d --wait
```

Yeni konteyner üzerinden veritabanını sorgulayın:

```bash
docker compose -p lab-doc-02 exec -T database \
  psql -U devops -d training -c "SELECT * FROM lab_events;"
```

---

## 💡 Hacimler ve Ortam Değişkenleri İnteraktif Pratik Alıştırmaları

#### Soru 1: Docker CLI ile Named Volume Oluşturma ve İnceleme
> **Görev:** `my-db-data` adında bir named volume oluşturun ve disk üzerindeki mount noktasını `docker volume inspect` ile görüntüleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker volume create my-db-data
    docker volume inspect my-db-data
    ```

---

#### Soru 2: Bind Mount ile Yerel Klasörü Konteynere Bağlama
> **Görev:** `~/labs/html` adında bir klasör açıp içine `index.html` oluşturun. Bu klasörü `nginx:alpine` konteynerinin `/usr/share/nginx/html` dizinine bind mount (`-v`) ederek çalıştırın.

??? tip "💡 Çözümü Göster"
    ```bash
    mkdir -p ~/labs/html && echo "<h1>Bind Mount Test</h1>" > ~/labs/html/index.html
    docker run -d --name nginx-mount -p 8086:80 -v ~/labs/html:/usr/share/nginx/html:ro nginx:alpine
    curl http://localhost:8086
    docker rm -f nginx-mount
    ```

---

#### Soru 3: Ortam Değişkenini `docker run -e` ile Geçme
> **Görev:** `APP_ENV=production` ve `APP_PORT=9000` ortam değişkenlerini `alpine` konteynerine aktarıp `env` çıktısında görüntüleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker run --rm -e APP_ENV=production -e APP_PORT=9000 alpine env
    ```

---

## Beklenen Sonuç

Sorgu sonucunda `volume-ok` kaydı görünmelidir. Konteyner silinip yeniden üretilse dahi named volume içindeki veri korunur.

---

## Doğrulama

```bash
bash scripts/validate.sh
```

Başarılı sonuç: `[PASS] LAB-DOC-02 volume persistence verified.`

---

## Sorun Giderme

- **`password is required` Hatası:** `LAB_POSTGRES_PASSWORD` değişkenini `export LAB_POSTGRES_PASSWORD='training-only-password'` ile terminal oturumunuza verin.
- **Port Çakışması:** `5432` portunu kullanan başka bir PostgreSQL veya servis varsa `docker ps --filter publish=5432` ile tespit edip durdurun.
- **PostgreSQL Ready Değilse:** `docker compose -p lab-doc-02 logs database` çıktısını inceleyin.

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak

- [Hakan Bayraktar — Docker Commands Cheat Sheet with Examples](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f)

