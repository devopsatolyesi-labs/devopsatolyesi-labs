# LAB-DOC-10 — Docker İmaj, Konteyner ve Volume Yedekleme / Geri Yükleme

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-DOC-10.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-DOC-10.zip && cd LAB-DOC-10`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-DOC-10
cd ~/labs/LAB-DOC-10
```

### `starter/backup.sh`

```bash
mkdir -p "$(dirname -- starter/backup.sh)"
cat > starter/backup.sh <<'LAB_FILE_EOF_1'
#!/usr/bin/env bash
set -euo pipefail

# TODO: Aşağıdaki yedekleme işlemlerini tamamlayın:
# 1. 'alpine:3.21' imajını 'alpine-backup.tar.gz' olarak sıkıştırarak kaydedin (docker save + gzip)
# 2. 'test-app' adında bir volume oluşturup içerisine 'backup-test.txt' dosyası yazın
# 3. Geçici bir alpine container ile 'test-app' volume içeriğini 'volume-backup.tar.gz' dosyasına yedekleyin
LAB_FILE_EOF_1
```

### `starter/restore.sh`

```bash
mkdir -p "$(dirname -- starter/restore.sh)"
cat > starter/restore.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
set -euo pipefail

# TODO: Aşağıdaki geri yükleme işlemlerini tamamlayın:
# 1. 'alpine-backup.tar.gz' dosyasından imajı geri yükleyin (docker load)
# 2. 'restored-app-data' adında yeni bir volume oluşturun
# 3. 'volume-backup.tar.gz' arşivini yeni volume içerisine açın
LAB_FILE_EOF_2
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-10] Temizleniyor..."
docker volume rm -f test-app-data restored-app-data 2>/dev/null || true
rm -f alpine-backup.tar.gz volume-backup.tar.gz 2>/dev/null || true
echo "[BİLGİ] LAB-DOC-10 kaynakları temizlendi."
LAB_FILE_EOF_3
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-10] Sıfırlanıyor..."
docker volume rm -f test-app-data restored-app-data 2>/dev/null || true
rm -f alpine-backup.tar.gz volume-backup.tar.gz 2>/dev/null || true
cp -a starter/. .
echo "[BİLGİ] LAB-DOC-10 başlangıç durumuna sıfırlandı."
LAB_FILE_EOF_4
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_5'
#!/usr/bin/env bash
set -euo pipefail

echo "==> [LAB-DOC-10] Doğrulama Başlatılıyor: Docker Backup & Restore..."

if [[ ! -f backup.sh || ! -f restore.sh ]]; then
  echo "[HATA] backup.sh veya restore.sh bulunamadı! Lütfen ~/labs/LAB-DOC-10 dizininde çalıştırın." >&2
  exit 1
fi

chmod +x backup.sh restore.sh

echo "[1/3] backup.sh çalıştırılıyor..."
bash backup.sh >/dev/null 2>&1

if [[ ! -f alpine-backup.tar.gz || ! -f volume-backup.tar.gz ]]; then
  echo "[HATA] Beklenen yedek dosyaları (alpine-backup.tar.gz, volume-backup.tar.gz) üretilemedi!" >&2
  exit 1
fi

echo "[2/3] restore.sh çalıştırılıyor..."
bash restore.sh >/dev/null 2>&1

echo "[3/3] Geri yüklenen verinin doğruluğu kontrol ediliyor..."
output=$(docker run --rm -v restored-app-data:/data alpine:3.21 cat /data/backup-test.txt 2>/dev/null || true)

if [[ "$output" == *"DevOps Atolyesi"* ]]; then
  echo "[PASS] Docker İmaj ve Volume Backup/Restore doğrulaması eksiksiz geçti!"
  exit 0
else
  echo "[FAIL] Geri yüklenen volume verisi doğrulanamadı. Çıktı: '$output'" >&2
  exit 1
fi
LAB_FILE_EOF_5
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## Amaç

Bu labın amacı, Docker ortamlarındaki imajların, çalışan konteynerlerin ve kalıcı veri alanlarının (**Named Volumes**) güvenli şekilde yedeklenmesini (Backup), taşınmasını (Migration) ve geri yüklenmesini (Restore) uygulamalı olarak öğrenmektir:

- `docker save` ve `docker load` ile imajları katman geçmişi ve etiketleriyle birlikte taşınabilir `.tar.gz` arşivlerine dönüştürmek.
- `docker export` ve `docker import` ile bir konteynerin anlık dosya sistemini (rootfs) dışa/içe aktarmak ve farklarını kavramak.
- `docker commit` ile çalışan bir konteynerin anlık durumundan yeni bir imaj türetmek.
- Geçici yardımcı konteynerler (**Helper/Sidecar Container**) kullanarak Docker Named Volume verilerini host dosya sistemine güvenle yedeklemek ve geri yüklemek.

---

## Ön Koşullar

> [!IMPORTANT]
> Bu labı uygulayabilmek için Docker Engine ortamınızın hazır olması gerekir.
> - Henüz kurulu değilse: [🛠️ Docker Engine Kurulum Rehberi](../../setup/docker-engine.md) adımlarını izleyin.

Hızlı sistem ön kontrolü:

```bash
docker --version
docker volume ls
```

---

## Yedekleme ve Taşıma Mimarisi

```text
1. İmaj Düzeyi:
   [ Local Docker Image ] --(docker save | gzip)--> [ image-backup.tar.gz ]
   [ image-backup.tar.gz ] --(docker load)--> [ Docker Daemon (Katmanlar Korunur) ]

2. Volume Düzeyi:
   [ Named Volume ] <--(Mount)-- [ Geçici Alpine Container ] --(tar czf)--> [ volume-backup.tar.gz ]
   [ volume-backup.tar.gz ] --(tar xzf)---> [ Yeni Named Volume ]
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-10
cd ~/labs/LAB-DOC-10
```

ZIP indirdiyseniz `unzip LAB-DOC-10.zip && cd LAB-DOC-10` komutunu çalıştırın.

---

### Adım 2: Docker İmajını Arşivleme (Save & Load)

Bir imajı tüm katmanlarıyla birlikte tek bir sıkıştırılmış arşiv dosyasına dönüştürün:

```bash
# İmajı indirin
docker pull alpine:3.21

# İmajı sıkıştırarak kaydedin
docker save alpine:3.21 | gzip > alpine-backup.tar.gz
ls -lh alpine-backup.tar.gz
```

İmajı yerelden silip arşivden geri yükleyerek test edin:

```bash
# Yerel imajı silin
docker rmi alpine:3.21

# Arşivden geri yükleyin
docker load < alpine-backup.tar.gz

# İmajın geri geldiğini doğrulayın
docker images alpine:3.21
```

---

### Adım 3: Çalışan Konteynerin Dosya Sistemini Dışa Aktarma (Export & Import)

Bir konteynerin anlık dosya sistemini dışarı aktarın:

```bash
# Test konteyneri başlatın ve içine dosya ekleyin
docker run -d --name snapshot-demo alpine:3.21 sh -c 'echo "Snapshot Test Verisi" > /tmp/demo.txt; sleep 3600'

# Konteyner dosya sistemini dışa aktarın
docker export snapshot-demo > container-fs.tar

# Dışa aktarılan arşivi yeni bir imaj olarak içe aktarın (CMD tanımlayarak)
cat container-fs.tar | docker import --change "CMD ["sh"]" - my-snapshot-image:v1

# Test edin
docker run --rm my-snapshot-image:v1 cat /tmp/demo.txt
docker rm -f snapshot-demo
```

---

### Adım 4: Docker Named Volume Yedekleme ve Taşıma

Docker volume'leri `/var/lib/docker/volumes` altında tutulduğundan doğrudan kopyalamak izin ve kilit sorunlarına yol açar. En güvenli yöntem geçici bir konteyner kullanmaktır:

```bash
# 1. Test volume oluşturun ve veri yazın
docker volume create test-app-data
docker run --rm -v test-app-data:/data alpine:3.21 sh -c 'echo "DevOps Atolyesi Backup Test $(date)" > /data/backup-test.txt'

# 2. Volume içeriğini host'a tar.gz olarak yedekleyin
docker run --rm   -v test-app-data:/data:ro   -v "$(pwd)":/backup   alpine:3.21 tar -czf /backup/volume-backup.tar.gz -C /data .

ls -lh volume-backup.tar.gz

# 3. Yeni bir volume oluşturun ve yedeği geri yükleyin
docker volume create restored-app-data
docker run --rm   -v restored-app-data:/data   -v "$(pwd)":/backup:ro   alpine:3.21 tar -xzf /backup/volume-backup.tar.gz -C /data

# 4. Geri yüklenen veriyi doğrulayın
docker run --rm -v restored-app-data:/data alpine:3.21 cat /data/backup-test.txt
```

---

### Adım 5: backup.sh ve restore.sh Scriptlerini Oluşturun

Otomatik doğrulama için dizinde `backup.sh` ve `restore.sh` scriptlerini tamamlayın:

```bash
cat <<'EOF' > backup.sh
#!/usr/bin/env bash
set -euo pipefail

docker pull alpine:3.21
docker save alpine:3.21 | gzip > alpine-backup.tar.gz

docker volume create test-app-data >/dev/null 2>&1 || true
docker run --rm -v test-app-data:/data alpine:3.21 sh -c 'echo "DevOps Atolyesi Backup Test $(date)" > /data/backup-test.txt'

docker run --rm   -v test-app-data:/data:ro   -v "$(pwd)":/backup   alpine:3.21 tar -czf /backup/volume-backup.tar.gz -C /data .
EOF

cat <<'EOF' > restore.sh
#!/usr/bin/env bash
set -euo pipefail

docker load < alpine-backup.tar.gz
docker volume create restored-app-data >/dev/null 2>&1 || true
docker run --rm   -v restored-app-data:/data   -v "$(pwd)":/backup:ro   alpine:3.21 tar -xzf /backup/volume-backup.tar.gz -C /data
EOF

chmod +x backup.sh restore.sh
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

Aşağıdaki soruları yanıtlamaya çalışın; ardından çözümü görmek için kutucuklara tıklayın:

??? question "Soru 1: `docker save` ile `docker export` arasındaki en temel fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        - **`docker save` (İmaj Düzeyi):** İmajın tüm katman geçmişini (layer history), etiketlerini (tags) ve metadata'sını (ENV, ENTRYPOINT, EXPOSE) korur. Boyutu daha büyüktür çünkü tüm ara katmanları içerir.
        - **`docker export` (Konteyner Düzeyi):** Çalışan veya durdurulmuş bir konteynerin anlık dosya sistemini (rootfs) tek bir düz katman (flattened) halinde arşivler. Tüm katman geçmişi, ENV değişkenleri ve ENTRYPOINT/CMD metadata'sı kaybolur.

??? question "Soru 2: `docker commit` kullanmanın üretimde önerilmeme, ancak troubleshooting/adli bilişim için çok değerli olma nedeni nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Üretimde önerilmez çünkü imajın içinde hangi komutların çalıştırıldığı, hangi dosyaların değiştirildiği şeffaf değildir (Infrastructure as Code ve Dockerfile prensibine aykırıdır). Ancak çöken veya saldırıya uğrayan bir konteyneri incelemek (Forensics/Debug) için anlık durumunu `docker commit my-compromised-container audit-image:v1` ile dondurup başka izole bir ortamda incelemek için mükemmel bir araçtır.

??? question "Soru 3: Docker Named Volume verilerini doğrudan ana makinedeki `/var/lib/docker/volumes/` altından `cp` ile kopyalamak neden önerilmez?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        İki ana nedeni vardır:
        1. **Dosya Kilitleri ve Tutarsızlık:** Veritabanı yazma anındayken doğrudan dosya kopyalamak bozuk (corrupted) veri oluşmasına yol açar.
        2. **İzinler ve Güvenlik:** `/var/lib/docker` dizinine yalnızca root erişebilir ve dosyaların UID/GID sahiplikleri kopyalama sırasında bozulabilir. Geçici bir container'ı `:ro` (read-only) bağlayıp `tar` ile almak dosya izinlerini ve yapısını eksiksiz korur.

??? question "Soru 4: Birden fazla Docker imajını tek bir arşiv dosyasında birleştirebilir miyiz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Evet, `docker save` komutuna birden fazla imaj adı verilebilir:
        ```bash
        docker save -o multi-images.tar nginx:alpine redis:alpine postgres:16
        ```
        Bu arşiv `docker load < multi-images.tar` ile açıldığında üç imaj da aynı anda Docker daemon'a yüklenir. Air-gapped (internetsiz) ortamlara paket taşırken çok sık kullanılır.

??? question "Soru 5: `docker import` ile bir tar arşivini imaja dönüştürdükten sonra `docker run` çalıştırıldığında neden 'no CMD specified' hatası alınır ve nasıl çözülür?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Çünkü `export` işlemi metadata'yı (CMD, ENTRYPOINT, WORKDIR) kaydederken atar. Çözmek için `docker import` komutuna `--change` bayrağı ile varsayılan komut eklenir:
        ```bash
        docker import --change "CMD ["nginx", "-g", "daemon off;"]" my-nginx.tar my-nginx:restored
        ```

---

## Doğrulama

```bash
bash scripts/validate.sh
```

---

## Sorun Giderme

- **Arşiv Bozulması:** `gzip: stdin: unexpected end of file` hatası alırsanız `save` işleminin disk doluluğu nedeniyle yarıda kalmadığından emin olun.
- **Volume Silinemiyor:** Volume başka bir konteyner tarafından kullanılıyorsa önce konteyneri `docker rm -f` ile kaldırın.

---

## Temizlik

```bash
bash scripts/cleanup.sh
```

---

## Kaynak ve Referanslar

Bu lab, [Backing Up and Restoring Docker Containers and Images — Hakan Bayraktar](https://hbayraktar.medium.com/backing-up-and-restoring-docker-containers-and-images-8e0b6ef5849b) makalesinden uyarlanmıştır.
