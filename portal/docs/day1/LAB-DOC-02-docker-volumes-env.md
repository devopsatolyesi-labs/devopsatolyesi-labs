# LAB-DOC-02 — Container Lifecycle, Exec, Env Vars & Volume Persistence

## Metadata
- **Seviye:** CORE
- **Önerilen Gün:** Gün 1
- **Tahmini Süre:** 40 dk
- **Gerekli Profil:** `docker`
- **Host Portları:** `5432:5432`
- **Çalışma Dizini:** `~/devops-workspace/labs/LAB-DOC-02`

---

## 1. Lab Senaryosu
Durum bilgisi tutan (stateful) uygulamaların ve veritabanlarının konteynerize edilmesi sürecinde veri kalıcılığı kritik bir gereksinimdir. Konteynerler varsayılan olarak geçicidir (ephemeral); konteyner yok edildiğinde kök dosya sistemindeki tüm veriler kaybolur. Bu çalışmada PostgreSQL veritabanı örneği üzerinden ortam değişkenleri yönetimi (`.env` dosyası enjeksiyonu), konteyner içerisine komut gönderme (`docker exec`) ve Named Volume kullanarak konteyner tamamen silinse dahi verinin korunması pratik edilir.

## 2. Amaç
Konteyner içine interaktif erişim sağlamak (`docker exec`), ortam değişkenlerini dosyadan enjekte etmek (`--env-file`), Docker Named Volume ile veri kalıcılığı sağlamak ve konteyner silinip yeniden oluşturulduğunda veri bütünlüğünü doğrulamak.

## 3. Mimari / Akış
```text
  [ Named Volume: pg_persistence_vol ]
                 |
                 v (Mounted to /var/lib/postgresql/data)
  [ Container: postgres-lifecycle-test (postgres:16-alpine) ]
        ^
        |-- Env: POSTGRES_DB=devops_db, POSTGRES_USER=devops_user
        |-- Mount (:ro): init.sql -> /docker-entrypoint-initdb.d/init.sql
```

## 4. Ön Koşullar
- Docker Engine çalışır durumda olmalıdır
- Host üzerinde 5432 portu boş olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-DOC-01`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
docker ps
docker volume ls
```

## 5. Adım Adım Uygulama

### Adım 1 — Çalışma Dizinini Hazırlama
Laboratuvar dizinini oluşturun:
```bash
mkdir -p ~/devops-workspace/labs/LAB-DOC-02
cd ~/devops-workspace/labs/LAB-DOC-02
```

### Adım 2 — Ortam Değişkenleri ve Başlangıç SQL Dosyasını Oluşturma
Yapılandırma dosyalarını oluşturun:
```bash
cat <<'EOF' > db.env
POSTGRES_DB=devops_db
POSTGRES_USER=devops_user
POSTGRES_PASSWORD=SuperSecretPassword123!
PGDATA=/var/lib/postgresql/data/pgdata
EOF

cat <<'EOF' > init.sql
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO audit_logs (event_name) VALUES ('CONTAINER_LIFECYCLE_STARTED');
INSERT INTO audit_logs (event_name) VALUES ('VOLUME_PERSISTENCE_TEST');
EOF
```

### Adım 3 — Named Volume Oluşturma ve Konteyneri Başlatma
Kalıcı depolama alanını oluşturun ve konteyneri çalıştırın:
```bash
# Named Volume oluştur
docker volume create pg_persistence_vol

# Konteyneri başlat
docker run -d \
  --name postgres-lifecycle-test \
  --env-file db.env \
  -v pg_persistence_vol:/var/lib/postgresql/data \
  -v $(pwd)/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
  -p 5432:5432 \
  postgres:16-alpine

# Veritabanının hazır olmasını bekle
sleep 5
```

### Adım 4 — Konteyner İçinde Komut Çalıştırma ve Veriyi Sorgulama
`docker exec` ile konteyner içerisindeki `psql` aracını çalıştırarak başlangıç kayıtlarını kontrol edin:
```bash
docker exec -i postgres-lifecycle-test psql -U devops_user -d devops_db -c "SELECT * FROM audit_logs;"
```

### Adım 5 — Kalıcılık Testi: Konteyneri Silme ve Yeni Konteyner Bağlama
Mevcut konteyneri silin ve aynı verileri içeren yeni bir konteyneri aynı volume ile başlatın:
```bash
# Konteyneri sil
docker rm -f postgres-lifecycle-test

# Aynı Named Volume ile yeni konteyneri başlat (init.sql bağlanmaz)
docker run -d \
  --name postgres-reborn \
  --env-file db.env \
  -v pg_persistence_vol:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine

sleep 5

# Verilerin korunduğunu sorgula
docker exec -i postgres-reborn psql -U devops_user -d devops_db -c "SELECT count(*) FROM audit_logs;"
```

## 6. Beklenen Sonuç
Adım 4'teki SQL sorgu çıktısı:
```text
 id |         event_name          |         created_at         
----+-----------------------------+----------------------------
  1 | CONTAINER_LIFECYCLE_STARTED | ...
  2 | VOLUME_PERSISTENCE_TEST     | ...
(2 rows)
```

Adım 5'te yeni konteyner üzerinden yapılan sorgu çıktısı:
```text
 count 
-------
     2
(1 row)
```

## 7. Doğrulama
Yeni konteyner üzerinde 2 adet kaydın eksiksiz korunduğunu doğrulayın:
```bash
ROW_COUNT=$(docker exec -i postgres-reborn psql -U devops_user -d devops_db -t -A -c "SELECT count(*) FROM audit_logs;")
if [ "$ROW_COUNT" -eq 2 ]; then
  echo "VALIDATION SUCCESS: Volume persistence verified. Data survived container recreation."
else
  echo "VALIDATION FAILED: Expected 2 rows, found $ROW_COUNT." && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
PostgreSQL konteyneri sürekli yeniden başlar veya `Exited (1)` durumuna geçer.

### Kanıt
`docker logs postgres-lifecycle-test` çıktısında `FATAL: password cannot be empty` veya izin hatası görülür.

### Kontrol Komutu
```bash
docker logs postgres-lifecycle-test | tail -n 20
```

### Muhtemel Neden
`POSTGRES_PASSWORD` ortam değişkeni sağlanmamıştır veya `db.env` dosyası okunurken sözdizimi hatası oluşmuştur.

### Çözüm
`db.env` dosyasındaki değişkenleri kontrol edin ve konteyneri `--env-file db.env` parametresiyle tekrar başlatın:
```bash
docker rm -f postgres-lifecycle-test 2>/dev/null || true
docker run -d --name postgres-lifecycle-test --env-file db.env -v pg_persistence_vol:/var/lib/postgresql/data -p 5432:5432 postgres:16-alpine
```

### Tekrar Doğrulama
```bash
docker ps --filter "name=postgres-lifecycle-test"
# Konteyner Up durumunda olmalıdır.
```

## 9. Temizlik / Sıfırlama
Çalışan konteynerleri ve oluşturulan Named Volume'ü silin:
```bash
docker rm -f postgres-lifecycle-test postgres-reborn 2>/dev/null || true
docker volume rm pg_persistence_vol 2>/dev/null || true
rm -rf ~/devops-workspace/labs/LAB-DOC-02
```

## 10. Production Notu
Üretim veritabanlarında gizli anahtarlar ve şifreler düz metin `.env` dosyalarında tutulmaz; HashiCorp Vault veya Kubernetes Secret mekanizmalarıyla çalışma zamanında enjekte edilir. Ayrıca veritabanı volume'leri için periyodik snapshot (yedekleme) stratejileri uygulanmalı, host dosya sistemine doğrudan bağlanan yapılandırma dosyaları salt-okunur (`:ro`) olarak eklenmelidir.

## 11. Challenge
`docker volume inspect pg_persistence_vol` komutunu kullanarak host dosya sistemindeki gerçek depolama dizinini (`Mountpoint`) tespit edin ve bu dizin altındaki PostgreSQL binary veri dosyalarını listeleyin.
