# LAB-DOC-04 — Docker Volumes, Bind Mounts ve Veri Kalıcılığı

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 45 dakika | `docker` | `5432` |

[LAB-DOC-04.zip](/downloads/LAB-DOC-04.zip)


## Amaç

- Konteynerlerin geçici (ephemeral / stateless) yapısını ve veri kaybı riskini uygulamalı olarak görmek.
- **Named Volume (İsimlendirilmiş Hacim)** oluşturup PostgreSQL veritabanı ile veri kalıcılığını (persistence) test etmek.
- Konteyner silinip (`docker rm -f`) baştan oluşturulduğunda eski veritabanı kayıtlarının korunduğunu kanıtlamak.
- **Bind Mount** ile yerel geliştirme klasörünü konteynere bağlayıp eş zamanlı dosya senkronizasyonunu deneyimlemek.
- Docker volume yönetim komutlarını (`create`, `ls`, `inspect`, `prune`) öğrenmek.

---

## Ön Koşullar

- Docker Engine ortamının hazır olması.
- `5432` portunun boş olması.

---

## Depolama Mimarisi Karşılaştırması

```text
+-------------------------------------------------------------------------------+
| ANA MAKİNE (HOST DOSYA SİSTEMİ)                                               |
|                                                                               |
|   1. NAMED VOLUME:                                                            |
|      /var/lib/docker/volumes/pg-data/_data                                    |
|             |                                                                 |
|             +----------------------------+                                    |
|                                          |                                    |
|   2. BIND MOUNT:                         |                                    |
|      ~/labs/LAB-DOC-04/html/             |                                    |
|             |                            |                                    |
+-------------|----------------------------|------------------------------------+
              |                            |
              v                            v
+-------------------------------------------------------------------------------+
| DOCKER KONTEYNERLERİ                                                          |
|                                                                               |
|   [ Nginx Web Konteyneri ]                    [ PostgreSQL DB Konteyneri ]    |
|   Mount: /usr/share/nginx/html                Mount: /var/lib/postgresql/data |
|   (Bind Mount: Canlı Kod/HTML)                (Named Volume: Kalıcı Veri)     |
+-------------------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-04
cd ~/labs/LAB-DOC-04
```

---

### Adım 2: Named Volume Oluşturun

Veritabanı için Docker tarafından yönetilen bağımsız bir named volume oluşturun:

```bash
docker volume create pg-data
docker volume ls
docker volume inspect pg-data
```

---

### Adım 3: PostgreSQL Konteynerini Volume ile Başlatın

`pg-data` hacmini PostgreSQL'in standart veri dizinine (`/var/lib/postgresql/data`) bağlayarak konteyneri başlatın:

```bash
docker run -d \
  --name db-persistence-test \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=DevOpsSecret2026 \
  -e POSTGRES_DB=company \
  -v pg-data:/var/lib/postgresql/data \
  postgres:16-alpine
```

PostgreSQL'in hazır duruma gelmesini birkaç saniye bekleyin:

```bash
sleep 5
docker logs --tail 10 db-persistence-test
```

---

### Adım 4: Veritabanına Test Verisi Yazın

Konteyner içine `psql` komutu göndererek bir tablo açın ve örnek kayıtlar ekleyin:

```bash
docker exec -i db-persistence-test psql -U postgres -d company <<'SQL'
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL
);

INSERT INTO employees (name, role) VALUES 
  ('Ahmet Yilmaz', 'DevOps Lead'),
  ('Ayse Demir', 'Cloud Architect'),
  ('Mehmet Kaya', 'Site Reliability Engineer');

SELECT * FROM employees;
SQL
```

Tabloda 3 çalışanın eklendiğini terminalde görün.

---

### Adım 5: Konteyneri Acımasızca Silin! (Felaket Senaryosu)

Veritabanı konteynerini tamamen silin:

```bash
docker rm -f db-persistence-test
```

Konteyner tamamen yok edildi! Şimdi kontrol edin:

```bash
docker ps -a --filter name=db-persistence-test
```

Çıktı boş dönmelidir. Ancak `pg-data` hacmi hala yerinde mi?

```bash
docker volume ls --filter name=pg-data
```

---

### Adım 6: Yeni Bir Konteyner Başlatın ve Verileri Doğrulayın

Aynı `pg-data` hacmini bağlayarak yepyeni bir PostgreSQL konteyneri ayağa kaldırın:

```bash
docker run -d \
  --name db-recovered \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=DevOpsSecret2026 \
  -e POSTGRES_DB=company \
  -v pg-data:/var/lib/postgresql/data \
  postgres:16-alpine

sleep 5
```

Eski verilerin kurtarıldığını kanıtlamak için sorgu çalıştırın:

```bash
docker exec -i db-recovered psql -U postgres -d company -c "SELECT * FROM employees;"
```

3 çalışanın da eksiksiz şekilde yeni konteynerde mevcut olduğunu göreceksiniz! Veriler konteynerin yaşam döngüsünden başarıyla izole edilmiştir.

---

### Adım 7: Bind Mount Kullanımı (Host -> Konteyner Dosya Paylaşımı)

Bind Mount, host makinedeki belirli bir dizini doğrudan konteynere yansıtır (özellikle yerel geliştirme için idealdir):

```bash
mkdir -p html
cat <<'HTML' > html/index.html
<!DOCTYPE html>
<html>
<body>
  <h1>DevOps Atolyesi - Bind Mount Calisiyor!</h1>
</body>
</html>
HTML

# Dizini salt-okunur (:ro) olarak Nginx konteynerine bağlayın
docker run -d --name web-bind-mount -p 8085:80 -v "$(pwd)/html:/usr/share/nginx/html:ro" nginx:alpine

# Web yanıtını test edin
curl -s http://localhost:8085
```

Şimdi host üzerindeki dosyayı güncelleyin:

```bash
echo "<h2>Anlik guncelleme: Konteyneri yeniden baslatmaya gerek yok!</h2>" >> html/index.html
curl -s http://localhost:8085
```

Konteyneri yeniden başlatmadan değişikliğin anında yansıdığını gözlemleyin!

---

## Doğal Doğrulama ve Beklenen Sonuç

- Adım 6'da çalıştırılan `SELECT * FROM employees;` sorgusu konteyner silinmesine rağmen 3 satırı eksiksiz döner.
- Adım 7'de `curl http://localhost:8085` komutu hostta değiştirilen HTML içeriğini anında sunar.

---
