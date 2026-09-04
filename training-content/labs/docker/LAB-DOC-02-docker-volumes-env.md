# LAB-DOC-02 — Docker Compose ve Kalıcı Veriler

## Metadata

- **Seviye:** CORE
- **Süre:** 40 dakika
- **Profil:** `docker`
- **Port:** `5432`

## Amaç

- Compose ile PostgreSQL çalıştırmak.
- Ortam değişkenlerini güvenli biçimde vermek.
- Named volume içindeki verinin konteyner yenilendiğinde kaldığını doğrulamak.

## Ön Koşullar

- `LAB-DOC-01` tamamlanmış olmalıdır.
- Docker Compose v2 çalışmalıdır: `docker compose version`
- `5432` portu boş olmalıdır.

## Adımlar

### 1. Başlangıç dosyasını alın

```bash
cd labs/LAB-DOC-02
cp -a starter/. .
```

### 2. Compose tanımını tamamlayın

`compose.yaml` içinde PostgreSQL servisine şunları ekleyin:

- `POSTGRES_USER=devops`
- `POSTGRES_DB=training`
- Parolayı `LAB_POSTGRES_PASSWORD` değişkeninden alma
- `/var/lib/postgresql/data` yoluna bağlı `pgdata` named volume
- `5432:5432` port yönlendirmesi

> İpucu: Zorunlu değişken için `${LAB_POSTGRES_PASSWORD:?parola gerekli}` yazımı kullanılabilir.

### 3. Parolayı terminal oturumuna verin

```bash
export LAB_POSTGRES_PASSWORD='training-only-password'
docker compose -p lab-doc-02 config --quiet
```

Parolayı `compose.yaml` içine yazmayın.

### 4. Veritabanını başlatın

```bash
docker compose -p lab-doc-02 up -d
docker compose -p lab-doc-02 ps
```

### 5. Bir kayıt oluşturun

```bash
docker compose -p lab-doc-02 exec -T database \
  psql -U devops -d training -c \
  "CREATE TABLE IF NOT EXISTS lab_events(name text); INSERT INTO lab_events VALUES ('volume-ok');"
```

### 6. Konteyneri yenileyip veriyi kontrol edin

```bash
docker compose -p lab-doc-02 rm -sf database
docker compose -p lab-doc-02 up -d
docker compose -p lab-doc-02 exec -T database \
  psql -U devops -d training -c "SELECT * FROM lab_events;"
```

## Beklenen Sonuç

Sorgu sonucunda `volume-ok` kaydı görünmelidir. Konteyner değişmiş olsa da named volume korunur.

## Doğrulama

```bash
bash scripts/validate.sh
```

Başarılı sonuç: `[PASS] LAB-DOC-02 volume persistence verified.`

## Sorun Giderme

- `password is required`: `LAB_POSTGRES_PASSWORD` değişkenini yeniden export edin.
- `port is already allocated`: `docker ps --filter publish=5432` komutuyla çakışmayı bulun.
- PostgreSQL hazır değilse: `docker compose -p lab-doc-02 logs database` çıktısını kontrol edin.

## Temizlik

Bu komut yalnız `lab-doc-02` Compose projesini ve onun volume'ünü kaldırır:

```bash
bash scripts/cleanup.sh
```
