# LAB-DOC-17 — İmaj ve Volume Yedekleme / Geri Yükleme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 45 dakika | `docker` | `5432` |

[LAB-DOC-17.zip](/downloads/LAB-DOC-17.zip)


---

## Amaç

- Docker imajlarını internet/registry olmadan arşiv dosyası olarak paketlemek (`docker save`) ve başka makineye aktarmak (`docker load`).
- Docker Named Volume verilerini geçici yardımcı konteyner (helper container) kalıbı ile `tar.gz` formatında yedeklemek.
- Veri kaybı veya felaket senaryosu (disaster recovery) simüle ederek verileri sıfırdan geri yüklemek (restore).
- Veri bütünlüğünü (data integrity) PostgreSQL üzerinde tablo ve kayıt bazında doğrulamak.

---

## Ön Koşullar

- Docker Engine çalışır durumda olmalıdır.
- `tar` ve `gzip` araçları kurulu olmalıdır.

---

## Volume Yedekleme Yardımcı Konteyner Modeli

```text
[ DOCKER NAMED VOLUME ] (db-volume)
          │
          │ -v db-volume:/source:ro (Salt okunur bağlama)
          ▼
+-------------------------------------------------------------+
| GEÇİCİ YARDIMCI KONTEYNER (alpine:latest)                   |
|  - tar -czf /backup/db-backup.tar.gz -C /source .           |
+-------------------------------------------------------------+
          │
          │ -v $(pwd)/backups:/backup (Host dizini bağlama)
          ▼
[ HOST DİSKİ: ./backups/db-backup.tar.gz ]
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-17/backups
cd ~/labs/LAB-DOC-17
```

---

### Adım 2: Veritabanı ve Test Verisi Oluşturma

Bir named volume oluşturun ve PostgreSQL konteyneri başlatın:

```bash
docker volume create prod-pgdata

docker run -d \
  --name prod-db \
  -e POSTGRES_PASSWORD=MasterSecret2026 \
  -e POSTGRES_DB=companydb \
  -v prod-pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# Veritabanının hazır olmasını bekleyin
sleep 5
```

Veritabanına kritik müşteri kayıtları ekleyin:

```bash
docker exec -i prod-db psql -U postgres -d companydb <<'EOF'
CREATE TABLE customers (id SERIAL PRIMARY KEY, name VARCHAR(100), balance NUMERIC);
INSERT INTO customers (name, balance) VALUES ('Acme Corp', 250000.00);
INSERT INTO customers (name, balance) VALUES ('Globex Inc', 145000.50);
SELECT * FROM customers;
EOF
```

---

### Adım 3: Docker İmajını Dışa Aktarma (`docker save`)

İnternetsiz (air-gapped) ortamlara aktarmak için imajı arşivleyin:

```bash
docker save -o backups/postgres-16-alpine.tar postgres:16-alpine
ls -lh backups/postgres-16-alpine.tar
```

---

### Adım 4: Named Volume Verisini Arşivleme (Helper Container)

Veri tutarlılığı için veritabanı konteynerini geçici olarak durdurun ve yedeği alın:

```bash
docker stop prod-db

# Yardımcı Alpine konteyneri ile volume'u tar.gz olarak paketleyin
docker run --rm \
  -v prod-pgdata:/source:ro \
  -v $(pwd)/backups:/destination \
  alpine tar -czf /destination/prod-pgdata-backup.tar.gz -C /source .

ls -lh backups/prod-pgdata-backup.tar.gz
```

---

### Adım 5: Felaket Senaryosu (Disaster Simulation)

Konteyneri ve volume'u tamamen silerek veri kaybını simüle edin:

```bash
docker rm -f prod-db
docker volume rm prod-pgdata
docker rmi postgres:16-alpine
```

Artık sistemde ne imaj ne de veritabanı volume'u vardır!

---

### Adım 6: Sıfırdan Geri Yükleme (Disaster Recovery)

Önce imajı geri yükleyin:

```bash
docker load -i backups/postgres-16-alpine.tar
docker images postgres:16-alpine
```

Şimdi yeni bir volume oluşturup tar yedeğini içine açın:

```bash
docker volume create restored-pgdata

docker run --rm \
  -v restored-pgdata:/target \
  -v $(pwd)/backups:/source:ro \
  alpine tar -xzf /source/prod-pgdata-backup.tar.gz -C /target
```

Yeni volume ile veritabanını tekrar ayağa kaldırın:

```bash
docker run -d \
  --name restored-db \
  -e POSTGRES_PASSWORD=MasterSecret2026 \
  -e POSTGRES_DB=companydb \
  -v restored-pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

sleep 5
```

---

## Doğal Doğrulama

Kayıtların eksiksiz kurtarıldığını psql ile sorgulayın:

```bash
docker exec -i restored-db psql -U postgres -d companydb -c "SELECT * FROM customers;"
```

`Acme Corp` ve `Globex Inc` kayıtlarının başarıyla döndüğünü doğrulayın!

---

## Doğal Doğrulama ve Beklenen Sonuç

```text
 id |    name    |  balance  
----+------------+-----------
  1 | Acme Corp  | 250000.00
  2 | Globex Inc | 145000.50
(2 rows)
```
