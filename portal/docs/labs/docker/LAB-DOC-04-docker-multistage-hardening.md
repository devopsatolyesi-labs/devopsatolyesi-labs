# LAB-DOC-04 — Multi-Stage Build ve Non-Root Konteyner

## Metadata

- **Seviye:** PRACTITIONER
- **Süre:** 45 dakika
- **Profil:** `docker`
- **Port:** Yok

## Amaç

- Build ve runtime aşamalarını ayırmak.
- Konteyneri root olmayan kullanıcıyla çalıştırmak.
- İmaj yapılandırmasını otomatik doğrulamak.

## Ön Koşullar

- `LAB-DOC-03` tamamlanmış olmalıdır.
- Docker Engine çalışmalıdır.

## Adımlar

### 1. Starter dosyasını alın

```bash
cd labs/LAB-DOC-04
cp -a starter/. .
```

### 2. Dockerfile'ı tamamlayın

İstenen yapı:

1. İlk aşamanın adı `builder` olmalıdır.
2. `app.js` yalnız ilk aşamada üretilmelidir.
3. Runtime aşamasına yalnız `app.js` kopyalanmalıdır.
4. Runtime kullanıcısının UID değeri `10001` olmalıdır.

> İpucu: Aşamalar arasında dosya almak için `COPY --from=builder` kullanılır.

### 3. İmajı oluşturun ve inceleyin

```bash
docker build -t lab-doc-04-hardened:latest .
docker image inspect lab-doc-04-hardened:latest --format '{{.Config.User}}'
docker run --rm lab-doc-04-hardened:latest
```

## Beklenen Sonuç

- Image kullanıcı alanı `10001` olmalıdır.
- Konteyner çıktısı `Production Microservice` içermelidir.

## Doğrulama

```bash
bash scripts/validate.sh
```

## Sorun Giderme

- UID boşsa Dockerfile'da `USER 10001` satırını kontrol edin.
- `COPY --from` hatasında aşama adının `builder` olduğunu doğrulayın.

## Temizlik

```bash
bash scripts/cleanup.sh
```
