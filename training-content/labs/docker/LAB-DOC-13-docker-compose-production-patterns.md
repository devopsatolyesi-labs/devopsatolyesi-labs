# LAB-DOC-13 — Production-Ready Docker Compose

## Metadata

- **Seviye:** ADVANCED
- **Süre:** 60 dakika
- **Profil:** `docker`
- **Port:** `8080`

## Amaç

- Base, development ve production Compose dosyalarını ayırmak.
- Uygulama ve veri ağlarını izole etmek.
- Healthcheck, kaynak limiti, log rotasyonu ve profile kullanmak.

## Ön Koşullar

- `LAB-DOC-05` tamamlanmış olmalıdır.
- Docker Compose v2 çalışmalıdır.
- En az 4 GB boş bellek önerilir.

## Adımlar

### 1. Dosyaları hazırlayın

```bash
cd labs/LAB-DOC-13
cp -a starter/. .
cp .env.example .env
chmod 600 .env
```

`.env` içindeki eğitim parolasını kendi yerel değerinizle değiştirin. Dosyayı Git'e eklemeyin.

### 2. Birleştirilmiş yapılandırmayı inceleyin

```bash
docker compose --env-file .env -f compose.yaml -f compose.prod.yaml config --quiet
docker compose --env-file .env -f compose.yaml -f compose.prod.yaml config > /tmp/lab-doc-13-rendered.yaml
```

Şunları bulun:

- `x-logging` ve `x-app-defaults` ortak ayarları,
- `gateway_net` ve `data_net` ağları,
- PostgreSQL ve Redis healthcheck'leri,
- production kaynak limitleri.

### 3. Production stack'i başlatın

```bash
docker compose -p lab-doc-13 --env-file .env \
  -f compose.yaml -f compose.prod.yaml up -d --build --wait
```

### 4. Sağlık ve ağ izolasyonunu kontrol edin

```bash
curl --fail http://localhost:8080/healthz
docker compose -p lab-doc-13 --env-file .env \
  -f compose.yaml -f compose.prod.yaml ps
```

Host üzerinden `5432` ve `6379` portları yayınlanmamalıdır.

### 5. İsteğe bağlı profilleri görün

```bash
docker compose --env-file .env -f compose.yaml --profile worker config --services
docker compose --env-file .env -f compose.yaml --profile monitoring config --services
```

> İpucu: Development override otomatik yüklenebilir. Production testi için dosyaları `-f` ile açıkça belirtin.

## Beklenen Sonuç

Health endpoint'i `HEALTHY`, `CONNECTED`, `CONNECTED` değerlerini döndürmelidir. Yalnız gateway host'a açık olmalıdır.

## Doğrulama

```bash
bash scripts/validate.sh
```

## Sorun Giderme

- Değişken hatasında `.env` dosyasındaki üç PostgreSQL alanını kontrol edin.
- Sağlıksız serviste `docker compose ... logs <servis>` komutunu kullanın.
- `5432` açıksa production yerine development override çalışıyor olabilir.

## Temizlik

```bash
bash scripts/cleanup.sh
```
