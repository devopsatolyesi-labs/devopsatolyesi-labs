# LAB-DOC-04 — Multi-Stage Build ve Non-Root Konteyner

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-04.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-04.zip && cd LAB-DOC-04`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-04
cd ~/labs/LAB-DOC-04
```

### `starter/Dockerfile`

```bash
mkdir -p "$(dirname -- starter/Dockerfile)"
cat > starter/Dockerfile <<'LAB_FILE_EOF_1'
# TODO: Write hardened multi-stage Dockerfile
# Stage 1: builder (compile/bundle)
# Stage 2: runtime (minimal non-root user 10001)
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
docker rmi lab-doc-04-hardened:latest 2>/dev/null || true
echo "Cleanup completed for LAB-DOC-04."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-DOC-04..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
cp -a "$script_dir/../starter/." .
echo "Workspace reset to starter state for LAB-DOC-04."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-04: Multi-stage Hardening..."
stage_count=$(grep -Ec '^[[:space:]]*FROM[[:space:]]+' Dockerfile)
if [[ "$stage_count" -lt 2 ]]; then
    echo "[FAIL] Expected at least two Dockerfile stages, found $stage_count." >&2
    exit 1
fi
docker build -t lab-doc-04-hardened:latest . >/dev/null
configured_user=$(docker image inspect lab-doc-04-hardened:latest --format '{{.Config.User}}')
runtime_user=$(docker run --rm --entrypoint id lab-doc-04-hardened:latest -u)
if [[ "$configured_user" == "10001" && "$runtime_user" == "10001" ]]; then
    echo "[PASS] Multi-stage image executes as non-root user 10001."
    exit 0
else
    echo "[FAIL] Expected configured/runtime UID 10001, found '$configured_user'/'$runtime_user'." >&2
    exit 1
fi
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


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
