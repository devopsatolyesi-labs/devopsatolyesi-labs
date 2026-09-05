# Docker Engine ve Docker Compose Kurulum Rehberi

Bu rehber, eğitim lablarında kullanılmak üzere **Docker Engine** ve **Docker Compose (v2)** bileşenlerinin Ubuntu 22.04/24.04, Debian ve Amazon Linux 2023 işletim sistemlerine resmi ve güvenli yöntemlerle kurulumunu adım adım açıklar.

---

## 1. Ubuntu 22.04 / 24.04 LTS Üzerinde Kurulum

### Adım 1: Eski Sürümleri Temizleyin
Çakışmaları önlemek için eski ve gayriresmi Docker paketlerini kaldırın:

```bash
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
```

### Adım 2: Gerekli Paketleri ve Resmi GPG Anahtarını Ekleyin

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# GPG anahtar dizini
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Resmi APT deposunu ekleyin
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Adım 3: Docker Engine ve Eklentilerini Kurun

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Adım 4: Kullanıcı İzinlerini ve Servisi Yapılandırın

Kullanıcınızın `sudo` olmadan Docker komutlarını çalıştırabilmesi için:

```bash
# docker grubuna mevcut kullanıcıyı ekleyin
sudo usermod -aG docker "$USER"

# Servisin açılışta başlamasını sağlayın
sudo systemctl enable --now docker
```

**Not:** Grup üyeliğinin terminalde aktif olması için oturumu kapatıp açabilir veya `newgrp docker` komutunu çalıştırabilirsiniz.

---

## 2. Amazon Linux 2023 Üzerinde Kurulum

```bash
# Docker paketini yükleyin
sudo dnf install -y docker

# Docker Compose v2 plugin yükleyin
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Servisi başlatın ve izinleri verin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

---

## 3. Kurulum Doğrulama (Preflight Check)

Kurulumun eksiksiz ve doğru çalıştığını aşağıdaki komutlarla test edin:

```bash
# Docker versiyon kontrolü
docker --version
docker compose version

# Hello World testi
docker run --rm hello-world

# Docker daemon socket kontrolü
docker info | grep -E "Server Version|Operating System|Cgroup Driver"
```

---

## 4. Gelişmiş Docker Daemon Yapılandırması (Opsiyonel)

Logların disk alanını doldurmaması ve log boyutunun sınırlandırılması için `/etc/docker/daemon.json` dosyasını yapılandırın:

```bash
sudo tee /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
EOF

sudo systemctl restart docker
```
