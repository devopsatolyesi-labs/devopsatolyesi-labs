# LAB-DOC-06 — Trivy Güvenlik Kapısı

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-06.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-06.zip && cd LAB-DOC-06`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-06
cd ~/labs/LAB-DOC-06
```

### `starter/trivy-scan.sh`

```bash
mkdir -p "$(dirname -- starter/trivy-scan.sh)"
cat > starter/trivy-scan.sh <<'LAB_FILE_EOF_1'
#!/usr/bin/env bash
# TODO: Run Trivy with severity CRITICAL and exit-code 1
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
echo "Cleanup completed for LAB-DOC-06."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-DOC-06..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
cp -a "$script_dir/../starter/." .
echo "Workspace reset to starter state for LAB-DOC-06."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-06: Trivy Security Scan..."
grep -Eq -- '--severity([ =]+)CRITICAL' trivy-scan.sh || {
    echo "[FAIL] CRITICAL severity gate is missing." >&2
    exit 1
}
grep -Eq -- '--exit-code([ =]+)1' trivy-scan.sh || {
    echo "[FAIL] Blocking exit code is missing." >&2
    exit 1
}
grep -q -- '--ignore-unfixed' trivy-scan.sh || {
    echo "[FAIL] --ignore-unfixed is missing." >&2
    exit 1
}
bash trivy-scan.sh
echo "[PASS] Trivy blocking scan passed on hardened baseline image."
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

- İmajı Trivy ile taramak.
- Kritik bulguda komutun başarısız olmasını sağlamak.
- Güvenlik kontrolünü pipeline'da kullanılabilir hale getirmek.

## Ön Koşullar

- `LAB-DOC-03` tamamlanmış olmalıdır.
- Docker Engine çalışmalıdır.
- Trivy imajını indirebilmek için internet erişimi olmalıdır.

## Adımlar

### 1. Starter dosyasını alın

```bash
cd labs/LAB-DOC-06
cp -a starter/. .
```

### 2. Güvenlik komutunu tamamlayın

`trivy-scan.sh` dosyasında `alpine:3.21` imajını tarayın:

- Yalnız `CRITICAL` seviyesini kontrol edin.
- Düzeltilmemiş bulguları hariç bırakın.
- Kritik bulguda exit code `1` üretin.

> İpucu: Trivy seçenekleri `--severity`, `--ignore-unfixed` ve `--exit-code` şeklindedir.

### 3. Çalıştırın

```bash
chmod +x trivy-scan.sh
./trivy-scan.sh
echo "$?"
```

Başarılı tarama `0`, engellenen imaj `1` döndürmelidir.

## Doğrulama

```bash
bash scripts/validate.sh
```

Validator güvenlik seçeneklerinin bulunduğunu ve taramanın gerçekten çalıştığını kontrol eder.

## Sorun Giderme

- Docker socket hatasında Docker Engine durumunu kontrol edin.
- Trivy veritabanı indirilemiyorsa internet ve DNS erişimini kontrol edin.
- CI içinde aynı scripti ayrı bir güvenlik adımı olarak çalıştırın.

## Temizlik

Bu lab kalıcı konteyner veya volume oluşturmaz.

```bash
bash scripts/cleanup.sh
```
