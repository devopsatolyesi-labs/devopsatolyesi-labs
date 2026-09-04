# LAB-LNX-01 — Linux Preflight & Systemd Service Inspection

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-LNX-01.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-LNX-01.zip && cd LAB-LNX-01`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-LNX-01
cd ~/labs/LAB-LNX-01
```

### `starter/preflight_check.sh`

```bash
mkdir -p "$(dirname -- starter/preflight_check.sh)"
cat > starter/preflight_check.sh <<'LAB_FILE_EOF_1'
#!/usr/bin/env bash
set -euo pipefail
# TODO: Implement Linux preflight report for CPU, RAM, Disk, and Docker
echo "Running preflight..."
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
echo "Cleanup completed for LAB-LNX-01."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
echo "Resetting workspace for LAB-LNX-01..."
bash "$lab_dir/scripts/cleanup.sh"
cp -r "$lab_dir/starter"/. .
echo "Workspace reset to starter state for LAB-LNX-01."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-LNX-01: Linux Preflight..."
bash preflight_check.sh >/dev/null
echo "[PASS] LAB-LNX-01 Preflight check executed with exit code 0."
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## 1. Lab Senaryosu
Yeni sağlanan bir Ubuntu sunucu üzerine konteyner ve Kubernetes platformu kurulmadan önce sistem kaynaklarının ve çalışan servislerin doğrulanması gerekmektedir. Yetersiz disk alanı, bellek yetersizliği veya port çakışmaları (özellikle 80, 443 veya 53 portlarının dolu olması) dağıtım aşamasında beklenmedik kesintilere yol açar. Bu çalışmada Linux çekirdek araçları kullanılarak CPU, bellek, disk ve dinleyen ağ soketleri denetlenir; preflight durumunu raporlayan çalıştırılabilir bir script hazırlanır.

## 2. Amaç
Ubuntu sunucu üzerinde CPU çekirdekleri, kullanılabilir RAM, disk doluluk oranları ve systemd servislerini analiz ederek sistemin konteyner/Kubernetes iş yüklerine hazır olduğunu doğrulamak.

## 3. Mimari / Akış
```text
+-------------------------------------------------------------+
|                      Ubuntu 24.04 LTS                       |
|                                                             |
|  [ CPU & RAM Denetimi ] ---> free -h / lscpu / nproc        |
|  [ Disk Alanı Denetimi ] --> df -hT /                       |
|  [ Systemd Servisleri ] ---> systemctl is-active docker     |
|  [ Dinleyen Portlar ] -----> ss -tulpn / lsof -i            |
+-------------------------------------------------------------+
```

## 4. Ön Koşullar
- Ubuntu 24.04 LTS kurulu sunucu erişimi (SSH)
- Sudo yetkilerine sahip kullanıcı oturumu
- Gerekli paketler: `iproute2`, `procps`, `curl`

Aşağıdaki komutlarla başlangıç durumunu doğrulayın:
```bash
whoami
hostnamectl
```

## 5. Adım Adım Uygulama

### Adım 1 — Çalışma Dizinini Hazırlama
Çalışma dizinini ve script klasörünü oluşturun:
```bash
mkdir -p ~/labs/LAB-LNX-01/scripts
cd ~/labs/LAB-LNX-01
```

### Adım 2 — Sistem Kaynaklarını İnceleme
CPU, bellek ve disk durumunu kontrol edin:
```bash
# CPU çekirdek sayısı ve model bilgisi
lscpu | grep -E "Model name|CPU\(s\):|Thread\(s\) per core"

# Bellek ve Swap durumu
free -h

# Kök dosya sistemi disk kullanımı
df -hT /
```

### Adım 3 — Dinleyen Ağ Soketlerini Tespit Etme
Sistemde açık olan TCP ve UDP portlarını listeleyin:
```bash
sudo ss -tulpn
```

### Adım 4 — Preflight Kontrol Scriptini Oluşturma
Sistem durumunu tek seferde raporlayan otomatik denetim scriptini oluşturun:

```bash
cat <<'EOF' > ~/labs/LAB-LNX-01/scripts/preflight_check.sh
#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "  DEVOPS PRACTITIONER - PREFLIGHT REPORT "
echo "========================================="
echo "Date: $(date -u)"
echo "Hostname: $(hostname)"
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
echo "Kernel: $(uname -r)"

echo -e "\n[1] CPU & RAM Status:"
echo "-----------------------------------------"
echo "CPU Cores: $(nproc)"
free -h | awk 'NR==1{print $0} NR==2{print $0}'

echo -e "\n[2] Disk Space (/):"
echo "-----------------------------------------"
df -h / | awk 'NR==1{print $0} NR==2{print $0}'

echo -e "\n[3] Docker Status:"
echo "-----------------------------------------"
if command -v docker >/dev/null 2>&1; then
    echo "Docker Version: $(docker --version)"
    sudo systemctl is-active docker && echo "Docker Daemon: ACTIVE" || echo "Docker Daemon: INACTIVE"
else
    echo "Docker is NOT installed yet."
fi

echo -e "\n[4] Active Listening Ports:"
echo "-----------------------------------------"
sudo ss -tulpn | grep LISTEN | awk '{print $1, $5, $7}' | head -n 10

echo -e "\n========================================="
echo "  PREFLIGHT REPORT COMPLETED SUCCESSFUL  "
echo "========================================="
EOF
chmod +x ~/labs/LAB-LNX-01/scripts/preflight_check.sh
```

## 6. Beklenen Sonuç
Script çalıştırıldığında sistem donanımını, disk durumunu ve açık portları içeren şu çıktı üretilmelidir:
```bash
~/labs/LAB-LNX-01/scripts/preflight_check.sh
```
Çıktı:
```text
=========================================
  DEVOPS PRACTITIONER - PREFLIGHT REPORT 
=========================================
Date: ...
Hostname: ...
OS: Ubuntu 24.04...
Kernel: 6.8...

[1] CPU & RAM Status:
-----------------------------------------
CPU Cores: ...
               total        used        free      shared  buff/cache   available
Mem:           ...

[2] Disk Space (/):
-----------------------------------------
Filesystem      Size  Used Avail Use% Mounted on
...

[3] Docker Status:
-----------------------------------------
...

[4] Active Listening Ports:
-----------------------------------------
...

=========================================
  PREFLIGHT REPORT COMPLETED SUCCESSFUL  
=========================================
```

## 7. Doğrulama
Preflight scriptinin sıfır hata kodu ile sonlandığını teyit edin:
```bash
if ~/labs/LAB-LNX-01/scripts/preflight_check.sh > /dev/null; then
    echo "VALIDATION SUCCESS: Preflight check completed with exit code 0."
else
    echo "VALIDATION FAILED: Preflight script returned non-zero exit code." && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
Web servisi veya konteyner başlatılırken `Error: listen tcp 0.0.0.0:80: bind: address already in use` hatası alınır.

### Kanıt
Port 80 üzerinde başka bir servisin dinleme yaptığı görülür.

### Kontrol Komutu
```bash
sudo ss -tulpn | grep :80
# veya
sudo lsof -i :80
```

### Muhtemel Neden
İşletim sisteminde önceden kurulmuş Apache2 veya Nginx servisi çalışmaktadır.

### Çözüm
İlgili yerel servisi durdurun ve devre dışı bırakın:
```bash
sudo systemctl stop nginx apache2 2>/dev/null || true
sudo systemctl disable nginx apache2 2>/dev/null || true
```

### Tekrar Doğrulama
```bash
sudo ss -tulpn | grep :80
# Çıktı boş dönmelidir.
```

## 9. Temizlik / Sıfırlama
Oluşturulan çalışma dizinini sıfırlamak için:
```bash
rm -rf ~/labs/LAB-LNX-01
```

## 10. Production Notu
Üretim ortamlarında sistem konfigürasyonu ve preflight kontrolleri manuel komutlarla değil; Ansible playbookları veya Packer imaj derleme aşamalarında otomasyon testleriyle (InSpec, Goss) doğrulanmalıdır. Ayrıca `cgroups v2` denetimi ve Kubernetes kurulumu için swap alanının kapalı tutulması (`swapoff -a`) kurumsal bir kuraldır.

## 11. Challenge
Sistemde disk doluluk oranı %85'i aştığında veya boş bellek 500 MB altına düştüğünde hata koduyla (`exit 1`) sonlanan bir preflight assertion fonksiyonunu script içine ekleyin.
