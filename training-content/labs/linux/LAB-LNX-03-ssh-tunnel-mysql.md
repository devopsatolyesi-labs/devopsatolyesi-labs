# LAB-LNX-03 — SSH Tunneling ile Güvenli Uzak Veritabanı Erişimi

## Metadata

- **Seviye:** PRACTITIONER
- **Süre:** 35 dakika
- **Profil:** `docker`
- **Port:** Yok

## Amaç

Bu labın amacı, doğrudan internete açık olmayan özel bir ağdaki (Private Subnet) **MySQL/PostgreSQL veritabanına**, bir atlama sunucusu (**Bastion Host / Jump Server**) üzerinden **SSH Local Port Forwarding (SSH Tünelleme)** kullanarak güvenli ve şifrelenmiş şekilde erişmeyi uygulamalı olarak öğrenmektir.

---

## Ön Koşullar

- SSH istemcisi kurulu olmalıdır (`ssh -V`).
- Bastion host ve hedef veritabanı ağ bilgisi.

---

## SSH Tünelleme Mimarisi

```text
[ Yerel Geliştirici Makinesi ]           [ Bastion Host (DMZ) ]          [ Private DB Sunucusu ]
localhost:33306 (Local Port)  =======>  Port 22 (SSH Tüneli)  =======>  10.0.2.50:3306 (MySQL)
(Dışarıdan kapalı)                     (İnternete açık SSH)             (Yalnızca iç ağa açık)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-LNX-03
cd ~/labs/LAB-LNX-03
```

ZIP indirdiyseniz `unzip LAB-LNX-03.zip && cd LAB-LNX-03` komutunu çalıştırın.

---

### Adım 2: SSH Local Port Forwarding Komutunu Oluşturun

```bash
cat <<'EOF' > tunnel-setup.sh
#!/usr/bin/env bash
set -euo pipefail

# SSH Local Port Forwarding parametreleri:
# -N : Uzak sunucuda komut çalıştırma (sadece tünel aç)
# -f : Arka planda (daemon/background) çalıştır
# -L [YEREL_PORT]:[HEDEF_DB_HOST]:[HEDEF_DB_PORT]

LOCAL_PORT="33306"
REMOTE_DB="10.0.2.50"
REMOTE_PORT="3306"
BASTION_USER="ubuntu"
BASTION_HOST="bastion.devopsatolyesi.local"

echo "==> SSH Tüneli Oluşturuluyor: localhost:$LOCAL_PORT -> $REMOTE_DB:$REMOTE_PORT"
echo "ssh -N -f -L $LOCAL_PORT:$REMOTE_DB:$REMOTE_PORT $BASTION_USER@$BASTION_HOST"
EOF

chmod +x tunnel-setup.sh
./tunnel-setup.sh
```

---

### Adım 3: Tünel Üzerinden Veritabanına Bağlanma

Tünel açıldıktan sonra, istemci aracınızı (DBeaver, MySQL CLI) doğrudan yerel makinenize bağlayabilirsiniz:

```bash
# Yerel port üzerinden uzak veritabanına bağlanın
mysql -h 127.0.0.1 -P 33306 -u dbuser -p
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: SSH tünelleme sırasında `-L`, `-R` ve `-D` bayrakları arasındaki fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        - **`-L` (Local Port Forwarding):** İstemcinin yerel portuna gelen trafiği uzak sunucu üzerinden hedef adrese yönlendirir (en yaygın kullanım: şirket içi veritabanına erişim).
        - **`-R` (Remote Port Forwarding):** Uzak sunucudaki bir portu yerel makinenizdeki bir servise yönlendirir (örneğin ngrok benzeri yerel API'yi dışarı açma).
        - **`-D` (Dynamic Port Forwarding):** Yerel makinenizi bir SOCKS proxy'ye dönüştürerek tüm tarayıcı trafiğini uzak sunucu üzerinden geçirir.

??? question "Soru 2: SSH tüneli kurarken neden `-N` ve `-f` bayrakları birlikte kullanılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `-N` uzakta bir kabuk (shell) açılmasını ve komut çalıştırılmasını engeller, yalnızca port tüneli kurulacağını belirtir. `-f` ise SSH sürecini arka plana (background) atar; böylece terminaliniz kilitlenmez ve script veya otomasyon devam edebilir.

---

## Kaynak ve Referanslar

Bu lab, [Secure Access to MySQL Port via SSH Tunnel — Hakan Bayraktar](https://hbayraktar.medium.com/secure-access-to-mysql-port-via-ssh-tunnel-fc1d01feffb9) makalesinden uyarlanmıştır.
