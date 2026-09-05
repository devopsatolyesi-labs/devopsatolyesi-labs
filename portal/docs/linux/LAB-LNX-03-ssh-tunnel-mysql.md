# LAB-LNX-03 — SSH Tunneling ile Güvenli Uzak Veritabanı Erişimi

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 35 dakika | `docker` | `Küme içi` |

[LAB-LNX-03.zip](/downloads/LAB-LNX-03.zip)


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
ssh -N -f -o ExitOnForwardFailure=yes \
  -L "$LOCAL_PORT:$REMOTE_DB:$REMOTE_PORT" \
  "$BASTION_USER@$BASTION_HOST"
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

## Doğal Doğrulama ve Beklenen Sonuç

```bash
ss -ltn | grep ':33306'
nc -zv 127.0.0.1 33306
mysql -h 127.0.0.1 -P 33306 -u dbuser -p -e 'SELECT 1;'
```

Yerel port dinlemede olmalı, TCP bağlantısı kurulmalı ve sorgu `1` sonucunu döndürmelidir.
