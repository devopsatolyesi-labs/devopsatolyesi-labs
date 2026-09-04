# LAB-LNX-01 — Linux Preflight & Systemd Service Inspection

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 30 dakika | `docker` | `22` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-LNX-01.zip)](/downloads/LAB-LNX-01.zip) — paket README ve başlangıç kodlarını içerir; çözüm içermez.
> 
> **Terminalde çalışma ortamını hazırlayın:**
> ```bash
> mkdir -p ~/labs/LAB-LNX-01
> cd ~/labs/LAB-LNX-01
> ```


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


---

## 🛠️ DevOps İçin En Çok Kullanılan Linux Komutları (Cheat Sheet)

Sistem yöneticileri, DevOps ve SRE mühendislerinin üretim ortamlarında her gün kullandığı kritik komutlar:

### 1. Süreç ve Kaynak Yönetimi
```bash
# Sistemdeki süreçleri CPU ve RAM tüketimine göre sıralama
ps aux --sort=-%mem | head -n 10
ps aux --sort=-%cpu | head -n 10

# Belirli bir süreci ismine göre arama ve sonlandırma
pgrep -fl nginx
pkill -f "python3 app.py"

# Bellek kullanımını insan tarafından okunabilir (MB/GB) olarak izleme
free -h -w
vmstat 1 5
```

### 2. Ağ, Soket ve Port Denetimi
```bash
# Dinleyen TCP/UDP portlarını ve ilgili süreci listeleme (netstat alternatifi)
sudo ss -tulpn

# Belirli bir portun (ör. 8080) hangi işlem tarafından kilitlendiğini bulma
sudo lsof -i :8080

# Uzak sunucunun belirli bir portunun açık olup olmadığını test etme
nc -zv 192.168.1.50 6443
curl -Iv https://labs.devopsatolyesi.com
```

### 3. Disk ve Depolama Analizi
```bash
# Disk doluluk oranlarını ve dosya sistemi türlerini listeleme
df -hT /

# Bulunulan dizindeki en büyük ilk 10 klasörü tespit etme
du -ah . | sort -rh | head -n 10

# Diskteki 100 MB'tan büyük dosyaları bulma (log temizliği için)
find /var/log -type f -size +100M -exec ls -lh {} +
```

### 4. Systemd ve Log İnceleme (journalctl)
```bash
# Servis durumunu kontrol etme, başlatma, durdurma ve otomatik başlatmayı açma
sudo systemctl status docker
sudo systemctl restart docker
sudo systemctl enable --now docker
sudo systemctl daemon-reload

# Belirli bir servisin loglarını canlı (tail -f) izleme
sudo journalctl -u docker -f

# Yalnızca son 1 saatteki hata loglarını filtreleme
sudo journalctl -u docker --since "1 hour ago" -p err
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

Aşağıdaki soruları yanıtlamaya çalışın; ardından çözümü görmek için kutucuklara tıklayın:

??? question "Soru 1: Bir uygulamanız 8080 portunda başlamıyor ve 'Address already in use' hatası veriyor. Portu kilitleyen işlemi bulup zorla sonlandırmak için hangi iki komutu sırasıyla çalıştırırsınız?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        1. Portu dinleyen PID'yi bulun:
           ```bash
           sudo lsof -i :8080 -t
           # veya: sudo ss -tulpn | grep 8080
           ```
        2. Tespit edilen PID'yi (ör. 4521) sonlandırın:
           ```bash
           sudo kill -9 4521
           ```

??? question "Soru 2: `systemctl restart my-service` komutu çalıştırıldığında hata alıyorsunuz. Servisin neden ayağa kalkamadığını en hızlı şekilde nereden ve hangi komutla incelersiniz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `journalctl` aracı ile servisin standart hata (stderr) çıktıları incelenir:
        ```bash
        sudo journalctl -u my-service -n 50 --no-pager
        ```
        `-n 50` son 50 satırı gösterir, `--no-pager` ise çıktıyı terminalde cat gibi doğrudan basar.

??? question "Soru 3: Linux'ta bir dosyanın izinleri `chmod 755 script.sh` ve `chmod 600 id_rsa` yapıldığında bu sayıların ifade ettiği yetki dağılımı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Linux'ta `Read (4)`, `Write (2)`, `Execute (1)` değerlerini temsil eder:
        - **`755`:** Sahip (4+2+1=7: rwx), Grup (4+0+1=5: r-x), Diğerleri (4+0+1=5: r-x). Scriptler ve çalıştırılabilir dosyalar için standarttır.
        - **`600`:** Sahip (4+2+0=6: rw-), Grup (0: ---), Diğerleri (0: ---). SSH private key ve hassas konfigürasyonlar için zorunlu güvenlik standardıdır.

??? question "Soru 4: Sunucuda disk dolduğu için servisler çöküyor (`No space left on device`). `/var/log` altında en çok yer kaplayan dosyaları tespit edip güvenle sıfırlamak (silmeden boyutunu 0 yapmak) için hangi komut kullanılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        En büyük dosyaları listelemek için:
        ```bash
        du -ah /var/log | sort -rh | head -n 5
        ```
        Çalışan bir servisin log dosyasını `rm` ile silerseniz dosya tanıtıcısı (file descriptor) açık kalacağından disk boşalmaz. Dosyayı silmeden sıfırlamak için:
        ```bash
        sudo truncate -s 0 /var/log/app/huge.log
        # veya: sudo : > /var/log/app/huge.log
        ```

??? question "Soru 5: Sunucuda anlık CPU yükünü (Load Average) ve çekirdek başına yük dağılımını terminalden en hızlı nasıl görürsünüz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `uptime` veya `top` komutu çalıştırılır. `top` ekranında `1` tuşuna basıldığında CPU çekirdekleri tek tek (Cpu0, Cpu1, Cpu2...) ayrıntılanır. `Load Average` değerinin (1, 5 ve 15 dk) CPU çekirdek sayısından (`nproc`) düşük olması sistemin rahat çalıştığını gösterir.


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

## 10. Production Notu
Üretim ortamlarında sistem konfigürasyonu ve preflight kontrolleri manuel komutlarla değil; Ansible playbookları veya Packer imaj derleme aşamalarında otomasyon testleriyle (InSpec, Goss) doğrulanmalıdır. Ayrıca `cgroups v2` denetimi ve Kubernetes kurulumu için swap alanının kapalı tutulması (`swapoff -a`) kurumsal bir kuraldır.

## 11. Challenge
Sistemde disk doluluk oranı %85'i aştığında veya boş bellek 500 MB altına düştüğünde hata koduyla (`exit 1`) sonlanan bir preflight assertion fonksiyonunu script içine ekleyin.
