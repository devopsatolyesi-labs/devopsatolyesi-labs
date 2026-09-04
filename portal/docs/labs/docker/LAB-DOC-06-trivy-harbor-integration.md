# LAB-DOC-06 — Trivy Güvenlik Kapısı

## Metadata

- **Seviye:** PRACTITIONER
- **Süre:** 30 dakika
- **Profil:** `docker`
- **Port:** Yok

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
