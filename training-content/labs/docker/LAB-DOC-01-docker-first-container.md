# LAB-DOC-01 — İlk Docker Konteyneri

## Metadata

- **Seviye:** CORE
- **Süre:** 30 dakika
- **Profil:** `docker`
- **Port:** `8080`

## Amaç

- Docker Engine'in çalıştığını doğrulamak.
- Basit bir imaj oluşturup konteyner başlatmak.
- Port yönlendirmesini ve HTTP yanıtını test etmek.

## Ön Koşullar

```bash
docker version
docker info >/dev/null
```

Komutlar hata vermeden tamamlanmalıdır. `8080` portunun boş olduğundan emin olun.

## Adımlar

### 1. Başlangıç dosyalarını çalışma dizinine alın

İndirdiğiniz pakette bu labın klasörüne girin:

```bash
cd labs/LAB-DOC-01
cp -a starter/. .
```

### 2. Dockerfile'ı tamamlayın

`Dockerfile` içinde şu işleri yapan satırları yazın:

1. `python:3.11-alpine` taban imajını kullanın.
2. Çalışma dizinini `/app` yapın.
3. `app.py` dosyasını kopyalayın.
4. Uygulamayı `python app.py` ile başlatın.

> İpucu: Gerekli Dockerfile komutları `FROM`, `WORKDIR`, `COPY` ve `CMD`'dir.

### 3. İmajı oluşturun ve konteyneri başlatın

```bash
docker build -t devops-first-container:v1 .
docker run -d --name lab-doc-01-test -p 8080:8080 devops-first-container:v1
```

### 4. Sonucu kontrol edin

```bash
docker ps --filter name=lab-doc-01-test
curl http://localhost:8080
docker logs --tail 10 lab-doc-01-test
```

## Beklenen Sonuç

`curl` çıktısında aşağıdaki metin görülmelidir:

```text
Hello from DevOps Atolyesi LAB-DOC-01!
```

## Doğrulama

```bash
bash scripts/validate.sh
```

Başarılı sonuç: `[PASS] LAB-DOC-01 Container responds with HTTP 200`

## Sorun Giderme

- `permission denied`: Kullanıcının `docker` grubunda olduğunu `groups` ile kontrol edin.
- `port is already allocated`: `docker ps --filter publish=8080` ile portu kullanan konteyneri bulun.
- Build hatası: `Dockerfile` içindeki dosya adını ve `COPY app.py .` satırını kontrol edin.

## Temizlik

```bash
bash scripts/cleanup.sh
```
