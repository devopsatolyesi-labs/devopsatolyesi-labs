# LAB-DOC-03 — Docker İmaj Optimizasyonu ve Harbor

## Metadata

- **Seviye:** PRACTITIONER
- **Süre:** 60 dakika
- **Profil:** `docker` + `harbor`
- **Portlar:** `8000`, `8082`

## Amaç

- Büyük ve optimize edilmiş Docker imajlarını karşılaştırmak.
- Layer cache ve multi-stage build kullanmak.
- İmajı yerel Harbor registry'ye göndermek.

## Ön Koşullar

- `LAB-DOC-01` tamamlanmış olmalıdır.
- Docker ve yerel Harbor çalışmalıdır.
- Harbor'da `devops` projesi bulunmalıdır.

## Adımlar

### 1. Dosyaları hazırlayın

```bash
cd labs/LAB-DOC-03
cp -a starter/. .
```

Üç Dockerfile hazırdır:

- `Dockerfile.bloated`: karşılaştırma için kasıtlı olarak büyük.
- `Dockerfile.optimized`: slim taban ve doğru cache sırası.
- `Dockerfile.multistage`: build araçlarını runtime imajından ayırır.

### 2. İmajları oluşturun

```bash
docker build -f Dockerfile.bloated -t devops-demo-api:bloated .
docker build -f Dockerfile.optimized -t devops-demo-api:slim .
docker build -f Dockerfile.multistage -t devops-demo-api:multistage .
```

### 3. Boyutları karşılaştırın

```bash
docker image ls 'devops-demo-api'
docker history devops-demo-api:slim
docker history devops-demo-api:multistage
```

Multi-stage imajda derleyici paketleri runtime katmanında bulunmamalıdır.

### 4. Uygulamayı çalıştırın

```bash
docker run -d --name demo-api-container -p 8000:8000 devops-demo-api:multistage
curl --fail http://localhost:8000/healthz
```

Beklenen yanıt: `{"status":"UP"}`

### 5. Harbor'a gönderin

```bash
export HARBOR_REGISTRY=${HARBOR_REGISTRY:-localhost:8082}
docker login "$HARBOR_REGISTRY"
docker tag devops-demo-api:multistage "$HARBOR_REGISTRY/devops/order-api:1.0.0"
docker push "$HARBOR_REGISTRY/devops/order-api:1.0.0"
```

> İpucu: HTTP kullanan yerel registry için Docker daemon yapılandırmasında `insecure-registries` gerekebilir.

## Doğrulama

```bash
bash scripts/validate.sh
```

Validator HTTP yanıtını, imaj boyutlarını ve Harbor'daki uzak manifesti kontrol eder.

## Sorun Giderme

- `connection refused`: Harbor profilini ve `8082` portunu kontrol edin.
- `unauthorized`: `docker login "$HARBOR_REGISTRY"` komutunu yeniden çalıştırın.
- API başlamıyorsa: `docker logs demo-api-container` çıktısını inceleyin.

## Temizlik

```bash
bash scripts/cleanup.sh
```
