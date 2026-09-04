# LAB-DOC-05 — Docker Compose ile Çok Katmanlı Uygulama

## Metadata

- **Seviye:** PRACTITIONER
- **Süre:** 60 dakika
- **Profil:** `docker`
- **Port:** `8080`

## Amaç

- API, PostgreSQL ve Redis servislerini Compose ile çalıştırmak.
- Servisleri özel ağda DNS adlarıyla bağlamak.
- Healthcheck tabanlı başlatma sırası kurmak.

## Ön Koşullar

- `LAB-DOC-02` tamamlanmış olmalıdır.
- Docker Compose v2 çalışmalıdır.
- `8080` portu boş olmalıdır.

## Adımlar

### 1. Başlangıç dosyalarını alın

```bash
cd labs/LAB-DOC-05
cp -a starter/. .
```

`app/` altında hazır API uygulaması bulunur. Bu labda `compose.yaml` dosyasını tamamlayacaksınız.

### 2. Üç servisi tanımlayın

`compose.yaml` içinde:

- PostgreSQL için named volume ve `pg_isready` healthcheck,
- Redis için `redis-cli ping` healthcheck,
- API için `8080:8080` portu ve DB/Redis ortam değişkenleri,
- API bağımlılıklarında `condition: service_healthy`,
- bütün servisler için `backend-net` ağı tanımlayın.

> İpucu: Veritabanı ve Redis portlarını host'a açmayın; API bu servislere Compose DNS adlarıyla ulaşır.

### 3. Parolayı verin ve yapıyı kontrol edin

```bash
export LAB_POSTGRES_PASSWORD='training-only-password'
docker compose -p lab-doc-05 config --quiet
```

### 4. Stack'i başlatın

```bash
docker compose -p lab-doc-05 up -d --build --wait
docker compose -p lab-doc-05 ps
```

### 5. Servis iletişimini test edin

```bash
curl --fail http://localhost:8080/healthz
curl --fail http://localhost:8080/
curl --fail http://localhost:8080/
```

## Beklenen Sonuç

- Health endpoint'i DB ve Redis için `OK` döndürür.
- İkinci `/` isteğinde Redis sayacı artar.
- Host'ta yalnız API portu yayınlanır.

## Doğrulama

```bash
bash scripts/validate.sh
```

## Sorun Giderme

- API sağlıksızsa: `docker compose -p lab-doc-05 logs api-service`
- DB sağlıksızsa: `docker compose -p lab-doc-05 logs postgres-db`
- Compose değişken hatasında `LAB_POSTGRES_PASSWORD` değerini kontrol edin.

## Temizlik

```bash
bash scripts/cleanup.sh
```
