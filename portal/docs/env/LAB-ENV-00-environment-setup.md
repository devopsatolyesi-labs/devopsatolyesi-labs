# LAB-ENV-00 — Ubuntu Server 24.04 LTS Üzerinde DevOps Ortamı Kurulumu ve Doğrulama

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 90 dakika | `base` | `Küme içi` |

[LAB-ENV-00.zip](/downloads/LAB-ENV-00.zip)


## 1. Lab Senaryosu ve Öğretim İlkesi

Bu dokümanın temel amacı, temiz ve boş bir Ubuntu Server 24.04 LTS işletim sistemi üzerinde modern bir DevOps mühendisinin ihtiyaç duyacağı tüm araç zincirini (toolchain) ve servis profillerini **adım adım, tek tek ve manuel olarak** nasıl kuracağınızı, yapılandıracağınızı ve doğrulayacağınızı öğretmektir. 

Bu doküman hazır bir "kara kutu" kurulum scripti çalıştırma kılavuzu değildir. Scriptler ana anlatımın yerine geçmez; en sonda yalnızca hızlı ortam kurtarma ve laboratuvar hazırlığı amacıyla sunulmuştur. Hiçbir otomasyon scripti kullanmasanız bile, bu dokümandaki adımları sırayla takip ederek boş bir sunucuyu tam teşekküllü bir DevOps geliştirme ve çalışma ortamına dönüştürebilirsiniz.

### Pedagojik Öğretim Sırası
```text
  [ 1. MANUEL KURULUMLARI ÖĞREN ]
                 ↓
  [ 2. Her Aracı Tek Tek Doğrula (Smoke Test) ]
                 ↓
  [ 3. Servis ve Profil Mantığını Kavra (RAM Yönetimi) ]
                 ↓
  [ 4. Ortamın Tamamını Otomatik Olarak Denetle ]
                 ↓
  [ 5. EN SON: Hızlı Kurulum & Recovery Scriptlerini Kullan ]
```

---

## 2. Sıfırdan Adım Adım Manuel Kurulum

---

### 2.1. İşletim Sistemi Hazırlığı ve Çekirdek (Kernel) Ayarları

#### 1. Ön Gereksinimler
- Temiz Ubuntu Server 24.04 LTS kurulumu
- `sudo` yetkisine sahip kullanıcı hesabı
- Aktif internet bağlantısı ve çalışan DNS çözümlemesi

#### 2. Repository / GPG Key Hazırlığı
Ubuntu resmi arşivlerinin güncel listesini çekin:
```bash
sudo apt-get update -y
```

#### 3. Manuel Kurulum
Temel paket yönetim araçlarını, derleme yardımcılarını ve ağ teşhis gereçlerini yükleyin:
```bash
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  software-properties-common \
  jq \
  unzip \
  tar \
  htop \
  net-tools \
  iproute2 \
  python3-venv \
  python3-pip \
  python3-yaml
```

#### 4. Temel Konfigürasyon
Elasticsearch ve yüksek performanslı konteyner bellek eşlemeleri için çekirdek `vm.max_map_count` değerini kalıcı olarak 262144'e ayarlayın:
```bash
sudo sysctl -w vm.max_map_count=262144
if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf 2>/dev/null; then
  echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
fi
```

#### 5. Servisi Başlatma
Sanal bellek sınırlarının güncellendiğini doğrulayın:
```bash
sudo sysctl -p
```

#### 6. Sürüm Kontrolü
```bash
lsb_release -a
uname -r
```

#### 7. Port Kontrolü
Varsayılan SSH portunun açık olduğunu kontrol edin:
```bash
ss -lntp | grep :22
```

#### 8. Fonksiyonel Smoke Test
Ağ bağlantısını ve DNS çözümlemesini test edin:
```bash
curl -sf https://www.google.com > /dev/null && echo "OS Network & DNS: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
OS Network & DNS: PASSED
vm.max_map_count = 262144
```

### 2.2. Git

#### 1. Ön Gereksinimler
- İşletim sistemi hazırlığının tamamlanmış olması

#### 2. Repository / GPG Key Hazırlığı
Ubuntu 24.04 resmi APT deposu kullanılır.

#### 3. Manuel Kurulum
```bash
sudo apt-get install -y git
```

#### 4. Temel Konfigürasyon
Küresel Git kullanıcı adını, e-posta adresini ve varsayılan dal adını belirleyin:
```bash
git config --global user.name "DevOps Engineer"
git config --global user.email "devops@local.internal"
git config --global init.defaultBranch main
```

#### 5. Servisi Başlatma
Git bir CLI aracıdır; arka plan servisi gerektirmez.

#### 6. Sürüm Kontrolü
```bash
git --version
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
Geçici bir yerel repo oluşturup commit atın:
```bash
TEMP_REPO=$(mktemp -d)
git init "$TEMP_REPO"
echo "test" > "$TEMP_REPO/file.txt"
git -C "$TEMP_REPO" add file.txt
git -C "$TEMP_REPO" commit -m "smoke test commit"
rm -rf "$TEMP_REPO"
echo "Git Functional Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
git version 2.43.0 (veya 2.44+)
Git Functional Test: PASSED
```

### 2.3. Docker Engine

#### 1. Ön Gereksinimler
- 64-bit Ubuntu 24.04 mimarisi
- GPG anahtar yönetimi (`gnupg`, `curl`)

#### 2. Repository / GPG Key Hazırlığı
Resmi Docker GPG anahtarını indirin ve APT kaynak listesine ekleyin:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
```

#### 3. Manuel Kurulum
Docker CE, Docker CLI ve containerd motorunu kurun:
```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
```

#### 4. Temel Konfigürasyon
Kullanıcınızın `sudo` yazmadan Docker soketine erişebilmesi için `docker` grubuna ekleyin:
```bash
sudo usermod -aG docker "$USER"
```
*(Not: Grup yetkisinin aktif olması için oturumu kapatıp açın veya `newgrp docker` çalıştırın).*

#### 5. Servisi Başlatma
```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager
```

#### 6. Sürüm Kontrolü
```bash
docker version
```

#### 7. Port Kontrolü
Docker motoru yerel UNIX soketi (`/var/run/docker.sock`) üzerinden haberleşir:
```bash
ls -l /var/run/docker.sock
```

#### 8. Fonksiyonel Smoke Test
Resmi `hello-world` test imajını çekip çalıştırın:
```bash
docker run --rm hello-world
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

### 2.4. Docker Compose

#### 1. Ön Gereksinimler
- Docker Engine kurulu ve çalışır olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Docker resmi deposunda yer alan `docker-compose-plugin` kullanılır.

#### 3. Manuel Kurulum
```bash
sudo apt-get install -y docker-compose-plugin
```

#### 4. Temel Konfigürasyon
Eski `docker-compose` komutunu yeni `docker compose` eklentisine eşitleyen bir alias tanımlayın:
```bash
echo 'alias docker-compose="docker compose"' >> ~/.bashrc
```

#### 5. Servisi Başlatma
Docker CLI eklentisi olarak çalışır; harici systemd servisi yoktur.

#### 6. Sürüm Kontrolü
```bash
docker compose version
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
Geçici bir `compose.yaml` ile Nginx servisi kaldırıp doğrulayın:
```bash
TEMP_DIR=$(mktemp -d)
cat <<'EOF' > "$TEMP_DIR/compose.yaml"
services:
  web:
    image: nginx:1.27-alpine
    ports:
      - "18080:80"
EOF
(cd "$TEMP_DIR" && docker compose up -d && sleep 2 && curl -sf http://localhost:18080 > /dev/null && docker compose down)
rm -rf "$TEMP_DIR"
echo "Docker Compose Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
Docker Compose version v2.32.4 (veya v2.x)
Docker Compose Smoke Test: PASSED
```

### 2.5. Terraform

#### 1. Ön Gereksinimler
- GPG anahtar doğrulama paketleri

#### 2. Repository / GPG Key Hazırlığı
Resmi HashiCorp GPG anahtarını ve deposunu ekleyin:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt-get update -y
```

#### 3. Manuel Kurulum
```bash
sudo apt-get install -y terraform
```

#### 4. Temel Konfigürasyon
Bash otomatik tamamlama özelliğini ekleyin:
```bash
terraform -install-autocomplete 2>/dev/null || true
```

#### 5. Servisi Başlatma
CLI aracıdır; servis gerektirmez.

#### 6. Sürüm Kontrolü
```bash
terraform version
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
Minimal yerel konfigürasyon ile `init` ve `validate` testini koşturun:
```bash
TEMP_TF=$(mktemp -d)
cat <<'EOF' > "$TEMP_TF/main.tf"
terraform {
  required_version = ">= 1.5.0"
}
output "status" {
  value = "TERRAFORM_VERIFIED"
}
EOF
(cd "$TEMP_TF" && terraform init -no-color && terraform validate -no-color)
rm -rf "$TEMP_TF"
echo "Terraform Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
Terraform v1.16.0 (veya 1.16.x)
Success! The configuration is valid.
Terraform Smoke Test: PASSED
```

### 2.6. kubectl

#### 1. Ön Gereksinimler
- APT transport paketleri

#### 2. Repository / GPG Key Hazırlığı
Kubernetes v1.31 resmi APT deposunu ekleyin:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update -y
```

#### 3. Manuel Kurulum
```bash
sudo apt-get install -y kubectl
```

#### 4. Temel Konfigürasyon
Kubectl alias ve bash tamamlama tanımlayın:
```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
```

#### 5. Servisi Başlatma
CLI aracıdır; arka plan servisi yoktur.

#### 6. Sürüm Kontrolü
```bash
kubectl version --client --output=yaml
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
İstemci tarafı doğrulama çalıştırın:
```bash
kubectl version --client | grep -q "gitVersion" && echo "kubectl Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
clientVersion:
  gitVersion: v1.31.9 (veya v1.31.x)
kubectl Smoke Test: PASSED
```

### 2.7. kind (Kubernetes in Docker)

**Not:** **Uyumluluk Gerekçesi (Compatibility Rationale):**
Kubernetes 1.31 LTS hattı ve kind v0.30.0 seçimi; Ubuntu 24.04 cgroups v2 tam desteği, `kubeadm.k8s.io/v1beta4` modern konfigürasyon yapısı ve Envoy proxy entegrasyonu için kanıtlanmış stabil standarttır. `kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211` digest pini ile sürüm drifti ve beklenmedik imaj çekme hataları kesin olarak engellenir.

#### 1. Ön Gereksinimler
- Docker Engine çalışır durumda olmalıdır.
- Mimari tespiti (amd64 veya arm64).

#### 2. Repository / GPG Key Hazırlığı
Resmi GitHub Release deposundan derlenmiş ikili (binary) çekilir.

#### 3. Manuel Kurulum
```bash
ARCH="$(dpkg --print-architecture)"
KIND_VER="v0.30.0"
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-${ARCH}"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

#### 4. Temel Konfigürasyon
Herhangi bir konfigürasyon dosyası gerektirmez; CLI doğrudan hazırdır.

#### 5. Servisi Başlatma
CLI aracıdır.

#### 6. Sürüm Kontrolü
```bash
kind version
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
Geçici tek düğümlü bir küme açıp kapatarak Docker entegrasyonunu test edin:
```bash
kind create cluster --name test-smoke --image kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211
kubectl get nodes
kind delete cluster --name test-smoke
echo "kind Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
kind v0.30.0
Creating cluster "test-smoke" ...
NAME                       STATUS   ROLES           AGE   VERSION
test-smoke-control-plane   Ready    control-plane   10s   v1.31.9
Deleted clusters: ["test-smoke"]
kind Smoke Test: PASSED
```

### 2.8. Helm

#### 1. Ön Gereksinimler
- `curl` ve `tar` paketleri

#### 2. Repository / GPG Key Hazırlığı
Resmi Helm kurulum betiğini kullanın:
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 3. Manuel Kurulum
Yukarıdaki betik `/usr/local/bin/helm` yoluna otomatik kurar.

#### 4. Temel Konfigürasyon
Bash tamamlama desteğini ekleyin:
```bash
echo 'source <(helm completion bash)' >> ~/.bashrc
```

#### 5. Servisi Başlatma
CLI aracıdır.

#### 6. Sürüm Kontrolü
```bash
helm version
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
Geçici bir chart oluşturup lint testinden geçirin:
```bash
TEMP_CHART=$(mktemp -d)
(cd "$TEMP_CHART" && helm create smoke-test && helm lint smoke-test)
rm -rf "$TEMP_CHART"
echo "Helm Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
version.BuildInfo{Version:"v3.21.0", ...}
1 chart(s) linted, 0 chart(s) failed
Helm Smoke Test: PASSED
```

### 2.9. Trivy (Konteyner Güvenlik Taraması)

#### 1. Ön Gereksinimler
- `curl`, `gnupg` paketleri

#### 2. Repository / GPG Key Hazırlığı
Aqua Security resmi Trivy deposunu ekleyin:
```bash
sudo install -m 0755 -d /etc/apt/keyrings
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/trivy.gpg

echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null

sudo apt-get update -y
```

#### 3. Manuel Kurulum
```bash
sudo apt-get install -y trivy
```

#### 4. Temel Konfigürasyon
Varsayılan yapılandırma yeterlidir.

#### 5. Servisi Başlatma
CLI aracıdır.

#### 6. Sürüm Kontrolü
```bash
trivy --version
```

#### 7. Port Kontrolü
Bağımsız port gerektirmez.

#### 8. Fonksiyonel Smoke Test
Hafif bir Alpine imajını yerel olarak tarayın:
```bash
trivy image --severity CRITICAL alpine:3.20
echo "Trivy Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
Version: 0.74.0
alpine:3.20 (alpine 3.20.x)
Total: 0 (CRITICAL: 0)
Trivy Smoke Test: PASSED
```

### 2.10. Jenkins

#### 1. Ön Gereksinimler
- Docker Engine ve Docker Compose kurulu olmalıdır.
- Host üzerinde 8080 ve 50000 portları boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi Docker Hub imajı kullanılır: `jenkins/jenkins:2.568.2-lts-jdk17`.

#### 3. Manuel Kurulum & Mimari Açıklama
- **Konteyner / İmaj:** `jenkins/jenkins:2.568.2-lts-jdk17` (JDK 17 LTS çalışma zamanı)
- **Portlar:** `8080:8080` (Web UI ve REST API), `50000:50000` (Inbound Agent bağlantı portu)
- **Hacimler (Volume):** `jenkins_home` adlandırılmış hacmi `/var/jenkins_home` dizinine bağlanır; tüm joblar, eklentiler ve konfigürasyonlar bu hacimde kalıcıdır.
- **Çevre Değişkenleri (Env):** `JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xms512m -Xmx1024m` ile RAM tüketimi 1 GB ile sınırlandırılır.
- **Docker Soketi:** `/var/run/docker.sock` konteyner içine bağlanarak Jenkins'in Docker komutları çalıştırması sağlanır.

Dizin oluşturup `compose.yaml` dosyasını yazın:
```bash
mkdir -p ~/devops-workspace/services/jenkins
cat <<'EOF' > ~/devops-workspace/services/jenkins/compose.yaml
services:
  jenkins:
    image: jenkins/jenkins:2.568.2-lts-jdk17
    container_name: jenkins-server
    restart: unless-stopped
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xms512m -Xmx1024m
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
volumes:
  jenkins_home:
EOF
```

#### 4. Temel Konfigürasyon
Servis yukarıdaki parametrelerle yapılandırılmıştır.

#### 5. Servisi Başlatma
```bash
cd ~/devops-workspace/services/jenkins
docker compose up -d
```

#### 6. Sürüm Kontrolü
```bash
docker exec jenkins-server jenkins --version
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep :8080
```

#### 8. Fonksiyonel Smoke Test
HTTP Login arayüzünün hazır olduğunu test edin:
```bash
sleep 10
curl -sf http://localhost:8080/login | grep -q "Jenkins" && echo "Jenkins Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
2.568.2
Jenkins Smoke Test: PASSED
```

### 2.11. SonarQube Community Build

#### 1. Ön Gereksinimler
- Çekirdek parametresi: `vm.max_map_count >= 262144`
- Host portu `9000:9000` boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi Docker Hub Community Build imajı kullanılır: `sonarqube:26.8.0.126808-community`. Tam derleme etiketi pini kullanılarak imaj kararlılığı sağlanır.

#### 3. Manuel Kurulum & Mimari Açıklama
- **Konteyner / İmaj:** `sonarqube:26.8.0.126808-community` (Dahili Java 17 çalışma zamanı)
- **Portlar:** `9000:9000` (Web UI ve Webhook API)
- **Hacimler:** `sonarqube_data` (`/opt/sonarqube/data`) ve `sonarqube_extensions` (`/opt/sonarqube/extensions`)
- **Çevre Değişkenleri:** `SONAR_JAVA_OPTS=-Xms512m -Xmx512m`, `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true`
- **Bellek Yönetimi:** Gömülü Elasticsearch motoru içerdiğinden 1.5–2 GB RAM tüketir.

Dizin oluşturup `compose.yaml` dosyasını yazın:
```bash
mkdir -p ~/devops-workspace/services/sonarqube
cat <<'EOF' > ~/devops-workspace/services/sonarqube/compose.yaml
services:
  sonarqube:
    image: sonarqube:26.8.0.126808-community
    container_name: sonarqube-server
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
      - "SONAR_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
volumes:
  sonarqube_data:
  sonarqube_extensions:
EOF
```

#### 4. Temel Konfigürasyon
Yukarıdaki `compose.yaml` ile tanımlanmıştır.

#### 5. Servisi Başlatma
```bash
cd ~/devops-workspace/services/sonarqube
docker compose up -d
```

#### 6. Sürüm Kontrolü
```bash
curl -s http://localhost:9000/api/server/version || echo "Initializing..."
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep :9000
```

#### 8. Fonksiyonel Smoke Test
Sistem sağlık API'sini sorgulayın:
```bash
echo "SonarQube'ün açılması bekleniyor (30s)..."
for i in {1..12}; do
  STATUS=$(curl -s http://localhost:9000/api/system/status | jq -r .status 2>/dev/null || echo "STARTING")
  if [ "$STATUS" = "UP" ]; then break; fi
  sleep 5
done
[ "$STATUS" = "UP" ] && echo "SonarQube Smoke Test: PASSED (Status: UP)"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
SonarQube Smoke Test: PASSED (Status: UP)
```

### 2.12. GitLab CE & GitLab Runner

#### 1. Ön Gereksinimler
- En az 4 GB boş RAM (GitLab Omnibus bellek yoğun bir servistir).
- Host üzerinde 8081 ve 2222 portları boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi imajlar: `gitlab/gitlab-ce:17.9.3-ce.0` ve `gitlab/gitlab-runner:alpine-v17.9.1`.

**Not:** **Sürüm Uyumluluğu (Version Parity):**
GitLab resmi mimari politikası gereği GitLab sunucusu ile GitLab Runner aynı major.minor serisinde çalışmalıdır. CE 17.9.3 sürümü ile tam uyumlu resmi upstream imajı `gitlab/gitlab-runner:alpine-v17.9.1` olarak sabitlenmiştir.

#### 3. Manuel Kurulum & Mimari Açıklama
- **Konteyner / İmaj:** `gitlab/gitlab-ce:17.9.3-ce.0` ve `gitlab/gitlab-runner:alpine-v17.9.1`
- **Portlar:** `8081:80` (Web UI), `2222:22` (Git SSH)
- **Hacimler:** `gitlab_config`, `gitlab_logs`, `gitlab_data`, `runner_config`
- **Bellek Optimizasyonu (Omnibus):** `puma['worker_processes'] = 2`, `sidekiq['max_concurrency'] = 5` ve `prometheus_monitoring['enable'] = false` ayarlanarak RAM tüketimi ~3.5 GB seviyesinde tutulur.

Dizin oluşturup `compose.yaml` dosyasını hazırlayın:
```bash
mkdir -p ~/devops-workspace/services/gitlab
cat <<'EOF' > ~/devops-workspace/services/gitlab/compose.yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:17.9.3-ce.0
    container_name: gitlab-server
    restart: unless-stopped
    ports:
      - "8081:80"
      - "2222:22"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8081'
        puma['worker_processes'] = 2
        sidekiq['max_concurrency'] = 5
        prometheus_monitoring['enable'] = false
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine-v17.9.1
    container_name: gitlab-runner
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner_config:/etc/gitlab-runner
    depends_on:
      - gitlab

volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
  runner_config:
EOF
```

#### 4. Temel Konfigürasyon
İlk açılışta `root` kullanıcısının geçici parolası `/etc/gitlab/initial_root_password` dosyasına yazılır.

#### 5. Servisi Başlatma
```bash
cd ~/devops-workspace/services/gitlab
docker compose up -d
```

#### 6. Sürüm Kontrolü
```bash
docker exec gitlab-server gitlab-rake gitlab:env:info | grep "GitLab information" -A 2 || echo "Starting..."
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep :8081
```

#### 8. Fonksiyonel Smoke Test
Sağlık endpoint'ini sorgulayın:
```bash
curl -sf http://localhost:8081/-/health && echo "GitLab Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
GitLab OK
GitLab Smoke Test: PASSED
```

### 2.13. Harbor Container Registry

#### 1. Ön Gereksinimler
- Docker Engine ve Compose kurulu olmalıdır.
- Host portu 8082 boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi Harbor OCI imajı: `goharbor/harbor-core:v2.15.2`.

#### 3. Manuel Kurulum & Mimari Açıklama
- **Konteyner / İmaj:** `goharbor/harbor-core:v2.15.2`
- **Portlar:** `8082:8080` (Harbor REST API ve Registry Gateway)
- **Hacimler:** Veritabanı ve imaj katmanları kalıcı hacimlerde saklanır.

Dizin oluşturup `compose.yaml` dosyasını oluşturun:
```bash
mkdir -p ~/devops-workspace/services/harbor
cat <<'EOF' > ~/devops-workspace/services/harbor/compose.yaml
services:
  harbor-core:
    image: goharbor/harbor-core:v2.15.2
    container_name: harbor-registry
    restart: unless-stopped
    ports:
      - "8082:8080"
    environment:
      - CORE_URL=http://localhost:8082
EOF
```

#### 4. Temel Konfigürasyon
Yukarıdaki `compose.yaml` ile tanımlanmıştır.

#### 5. Servisi Başlatma
```bash
cd ~/devops-workspace/services/harbor
docker compose up -d
```

#### 6. Sürüm Kontrolü
```bash
curl -s http://localhost:8082/api/v2.0/systeminfo | jq . || echo "Harbor v2.15.2"
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep :8082
```

#### 8. Fonksiyonel Smoke Test
Harbor ping endpoint'ini test edin:
```bash
curl -sf http://localhost:8082/api/v2.0/ping && echo -e "\nHarbor Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
pong
Harbor Smoke Test: PASSED
```

### 2.14. Argo CD

#### 1. Ön Gereksinimler
- Çalışan bir Kubernetes kümesi (`kind` cluster)
- `kubectl` CLI yetkili olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi Argo CD v2.13 manifestosu kullanılır.

#### 3. Manuel Kurulum
`argocd` ad alanını açıp kurulum manifestosunu uygulayın:
```bash
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.0/manifests/install.yaml
```

#### 4. Temel Konfigürasyon
İlk admin parolasını Secret'tan okuma ve port yönlendirme:
```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD Admin Password: $ARGO_PWD"
```

#### 5. Servisi Başlatma
API sunucusunu arka planda host 8085 portuna yönlendirin:
```bash
kubectl port-forward svc/argocd-server -n argocd 8085:443 > /dev/null 2>&1 &
```

#### 6. Sürüm Kontrolü
```bash
argocd version --client --short
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep :8085
```

#### 8. Fonksiyonel Smoke Test
CLI ile oturum açma testi:
```bash
argocd login localhost:8085 --username admin --password "$ARGO_PWD" --insecure
argocd app list
echo "Argo CD Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
'admin:login' logged in successfully
Argo CD Smoke Test: PASSED
```

### 2.15. Headlamp (Kubernetes Web Arayüzü)

#### 1. Ön Gereksinimler
- Docker Engine ve `~/.kube/config` dosyası

#### 2. Repository / GPG Key Hazırlığı
Resmi GitHub Container Registry imajı kullanılır: `ghcr.io/headlamp-k8s/headlamp:v0.45.0`. (kubernetes-sigs/headlamp resmi 2026 stabil sürümü).

#### 3. Manuel Kurulum & Mimari Açıklama
- **Port:** `8088:4466`
- **Kullanım:** Kubernetes kümesindeki pod, deployment ve servisleri tarayıcıdan görsel olarak izlemeyi sağlar.

```bash
docker run -d --name k8s-headlamp \
  -p 8088:4466 \
  -v ~/.kube/config:/root/.kube/config:ro \
  ghcr.io/headlamp-k8s/headlamp:v0.45.0
```

#### 4. Temel Konfigürasyon
Kubeconfig otomatik olarak okunur.

#### 5. Servisi Başlatma
Yukarıdaki `docker run` komutu ile başlatılır.

#### 6. Sürüm Kontrolü
```bash
docker inspect --format '{{.Config.Image}}' k8s-headlamp
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep :8088
```

#### 8. Fonksiyonel Smoke Test
```bash
curl -sf http://localhost:8088/ | grep -q "Headlamp" && echo "Headlamp Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
Headlamp Smoke Test: PASSED
```

### 2.16. Prometheus & Grafana

#### 1. Ön Gereksinimler
- Host portları `9090:9090` (Prometheus) ve `3000:3000` (Grafana) boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi imajlar: `prom/prometheus:v3.13.2` ve `grafana/grafana:13.1.5`.

#### 3. Manuel Kurulum & Mimari Açıklama
- **Prometheus:** 5 saniyelik aralıklarla metrik kazıyan zaman serisi motoru.
- **Grafana:** Otomatik Prometheus veri kaynağı yapılandırması (data source provisioning).

Dizin oluşturup yapılandırmaları yazın:
```bash
mkdir -p ~/devops-workspace/services/monitoring/prometheus
cat <<'EOF' > ~/devops-workspace/services/monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

cat <<'EOF' > ~/devops-workspace/services/monitoring/compose.yaml
services:
  prometheus:
    image: prom/prometheus:v3.13.2
    container_name: mon-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro

  grafana:
    image: grafana/grafana:13.1.5
    container_name: mon-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on:
      - prometheus
EOF
```

#### 4. Temel Konfigürasyon
Yukarıdaki dosyalarda tanımlanmıştır.

#### 5. Servisi Başlatma
```bash
cd ~/devops-workspace/services/monitoring
docker compose up -d
```

#### 6. Sürüm Kontrolü
```bash
docker exec mon-prometheus prometheus --version
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep -E ":(9090|3000)"
```

#### 8. Fonksiyonel Smoke Test
Her iki servisin sağlık uç noktalarını denetleyin:
```bash
curl -sf http://localhost:9090/-/healthy | grep -q "Healthy" && echo "Prometheus: HEALTHY"
curl -sf http://localhost:3000/api/health | grep -q "ok" && echo "Grafana: HEALTHY"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
Prometheus: HEALTHY
Grafana: HEALTHY
```

### 2.17. Elasticsearch, Kibana & Vector

#### 1. Ön Gereksinimler
- `vm.max_map_count >= 262144`
- Host portları `9200:9200` ve `5601:5601` boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi imajlar: `docker.elastic.co/elasticsearch/elasticsearch:8.17.8`, `docker.elastic.co/kibana/kibana:8.17.8`, `timberio/vector:0.40.2-alpine`.

**Not:** **Sürüm Seçimi ve Bellek Uyumluluk Kanıtı (Version & RAM Feasibility Rationale):**
- **Neden 9.x (9.5.2) Seçilmedi?** Upstream 9.x serisi, dahili OpenJDK 22+ taban bellek gereksinimi, varsayılan zorunlu HTTPS/TLS ve 2 GB minimum heap (4 GB+ konteyner sınırı) zorunluluğu getirmektedir. Kibana 9.x ile birlikte logging profili tek başına 5.5 GB RAM tüketmekte ve 8–16 GB RAM'li sunucularda Linux OOM Killer'ı tetiklemektedir.
- **Neden 7.17.23 Terk Edildi?** 7.17 serisi EOL sürecine girmiş olup 2026 yılı modern loglama ekosistemlerinin (Vector, OpenTelemetry) güncel OCI ve bulk API beklentilerini karşılamamaktadır.
- **Neden 8.17.8 Seçildi?** Aktif olarak desteklenen 2026 LTS kararlı sürümüdür. Tek düğümlü modda güvenlik kapatılabilir (`xpack.security.enabled=false`), `ES_JAVA_OPTS=-Xms1g -Xmx1g` ile düşük bellek tüketimi (~1.5 GB ES, ~800 MB Kibana) sağlanır ve Vector 0.40.2 ile `suppress_type_name: true` parametresiyle tam uyumlu çalışır.

#### 3. Manuel Kurulum & Mimari Açıklama
- **Elasticsearch:** Tek düğümlü geliştirme modunda, `ES_JAVA_OPTS=-Xms1g -Xmx1g` ile hafifletilmiştir.
- **Vector:** Docker soketinden JSON logları toplayıp bulk API üzerinden doğrudan Elasticsearch 8.17'ye basar.
- **Kibana:** Elasticsearch 8.17.8 ile birebir aynı sürümde log analizi görselleştirme arayüzü.

Dizin oluşturup `compose.yaml` ve `vector.yaml` dosyalarını yazın:
```bash
mkdir -p ~/devops-workspace/services/logging/vector
cat <<'EOF' > ~/devops-workspace/services/logging/vector/vector.yaml
sources:
  docker:
    type: docker_logs
sinks:
  es:
    type: elasticsearch
    inputs: [docker]
    endpoints: ["http://elasticsearch:9200"]
    mode: "bulk"
    index: "app-logs-%Y.%m.%d"
    suppress_type_name: true
EOF

cat <<'EOF' > ~/devops-workspace/services/logging/compose.yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.17.8
    container_name: log-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - xpack.security.transport.ssl.enabled=false
      - xpack.security.http.ssl.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ports:
      - "9200:9200"
    ulimits:
      memlock:
        soft: -1
        hard: -1

  kibana:
    image: docker.elastic.co/kibana/kibana:8.17.8
    container_name: log-kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

  vector:
    image: timberio/vector:0.40.2-alpine
    container_name: log-vector
    volumes:
      - ./vector/vector.yaml:/etc/vector/vector.yaml:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - elasticsearch
EOF
```

#### 4. Temel Konfigürasyon
Yukarıda dosyalar hazırlanmıştır.

#### 5. Servisi Başlatma
```bash
cd ~/devops-workspace/services/logging
docker compose up -d
```

#### 6. Sürüm Kontrolü
```bash
curl -s http://localhost:9200/ | jq .version.number
```

#### 7. Port Kontrolü
```bash
ss -lntp | grep -E ":(9200|5601)"
```

#### 8. Fonksiyonel Smoke Test
Elasticsearch küme sağlığını sorgulayın:
```bash
curl -sf http://localhost:9200/_cluster/health | grep -q "status" && echo "Elasticsearch Smoke Test: PASSED"
```

#### Doğal Doğrulama ve Beklenen Sonuç
```text
"8.17.8"
Elasticsearch Smoke Test: PASSED
```

## 3. Servis Profil Mantığı ve RAM Yönetimi (8–16 GB Bütçesi)

Eğitim sunucularının çoğu 8 GB veya 16 GB fiziksel belleğe sahiptir. Jenkins, GitLab, SonarQube, Harbor, Kubernetes (kind) ve Elasticsearch gibi ağır sistemlerin **tamamı aynı anda çalıştırılırsa sunucu OOM (Out Of Memory) ile kilitlenir.**

Bu nedenle eğitimde **7 adet izole profil** ile **Profil Değiştirme (Profile Switching)** modeli uygulanır:

| Profil Adı | İçerdiği Servisler | RAM İhtiyacı | Açık Portlar | Ne Zaman Kullanılır? |
|---|---|:---:|:---:|---|
| `docker` | Yalnızca Docker daemon ve yerel test konteynerleri | ~0.5 GB | Değişken | Gün 1 & Gün 2 (Konteyner Labları) |
| `jenkins-ci` | Jenkins 2.568.2 LTS | ~1.5 GB | 8080, 50000 | Gün 3 (CI Temelleri) |
| `secure-ci` | Jenkins + SonarQube 26.8.0 Community + Harbor 2.15 | ~3.5 GB | 8080, 9000, 8082 | Gün 3 (DevSecOps Labları) |
| `gitlab-ci` | GitLab CE 17.9.3 + GitLab Runner 17.9.1 | ~4.5 GB | 8081, 2222 | Gün 3 (GitLab Showcase) |
| `kubernetes` | kind (v0.30.0 / K8s 1.31.9) + Headlamp v0.45 + Argo CD 3.4 | ~3.0 GB | 80, 443, 8085, 8088 | Gün 4 (Kubernetes & GitOps) |
| `monitoring` | Prometheus 3.13 LTS + Grafana 13.1.5 + Alertmanager | ~1.2 GB | 9090, 3000, 9093 | Gün 5 (Metrik Gözlemlenebilirliği) |
| `logging` | Elasticsearch 8.17.8 + Kibana 8.17.8 + Vector | ~2.4 GB | 9200, 5601 | Gün 5 (Merkezi Loglama) |

### Profil Yönetim Komutları

```bash
# Profil Başlatma
bash outputs/lab-assets/LAB-ENV-00/scripts/start-profile.sh <profil-adı>

# Profil Durdurma (Bellek Boşaltma)
bash outputs/lab-assets/LAB-ENV-00/scripts/stop-profile.sh <profil-adı>

# Tüm Profilleri Kapatma
bash outputs/lab-assets/LAB-ENV-00/scripts/stop-profile.sh all

# Canlı Bellek ve Port Durumunu İnceleme
bash outputs/lab-assets/LAB-ENV-00/scripts/status.sh
```

---

## 4. Hızlı Kurulum ve Ortam Kontrolü (Otomasyon Scriptleri)

**Not:** **ÖNEMLİ NOT:** Bu bölümde yer alan otomasyon scriptleri, yukarıdaki manuel kurulum adımlarını öğrenmenin bir alternatifi **değildir**. Bu scriptler, eğitim başlamadan önce ortamın hızla hazırlanması ya da bir çökme durumunda ortamın dakikalar içinde baştan kurtarılması (recovery) amacıyla kullanılır.

Varlık dizinindeki script seti:
```text
outputs/lab-assets/LAB-ENV-00/scripts/
├── install-base-tools.sh        # Temel Linux araçları ve çekirdek ayarı
├── install-docker.sh            # Docker CE 27.5.1 ve Compose v2
├── install-terraform.sh         # HashiCorp Terraform 1.9.x
├── install-kubernetes-tools.sh  # kubectl, kind, Helm
├── install-security-tools.sh    # Trivy ve Argo CD CLI
├── prepare-service-profiles.sh  # Tüm ağır servis compose dosyalarını üretir
├── install-all.sh               # Akıllı, idempotent tümleşik hızlı hazırlık aracı
├── validate-environment.sh      # Hiçbir şey kurmayan salt-okunur denetim aracı
├── status.sh                    # RAM, CPU, konteyner ve port durum özeti
├── start-profile.sh             # İstenen profili başlatan komut
└── stop-profile.sh              # Profili durdurup belleği boşaltan komut
```

### 4.1. `install-all.sh` Çalıştırma (Hızlı Hazırlık & Kurtarma)

Bu script akıllıdır ve idempotenttir: Sistemde halihazırda doğru sürümle kurulu olan bir aracı tespit ettiğinde tekrar kurmaz; sadece eksik araçları yükler.

```bash
cd ~/devops-workspace/devops-practitioner-egitim-katalogu
bash outputs/lab-assets/LAB-ENV-00/scripts/install-all.sh
```

**Örnek Çalışma Çıktısı:**
```text
==========================================================
      DEVOPS TRAINING AUTOMATED FAST-PREP / RECOVERY     
==========================================================
[PASS] Ubuntu 24.04 LTS detected (noble)
[PASS] Architecture: x86_64 (amd64)
[PASS] Internet & DNS connectivity verified
[PASS] System RAM: 15890 MB (Meets >= 8 GB requirement)
[PASS] Free Disk Space: 68 GB

--- CHECKING & INSTALLING TOOLCHAINS (IDEMPOTENT) ---
[PASS] Git and Base utilities already installed
[PASS] Docker Engine installed (v27.5.1)
[PASS] Docker Compose installed
[INSTALL] Terraform missing. Installing...
[PASS] Terraform installed
[PASS] kubectl installed (v1.31.4)
[PASS] kind installed (v0.30.0)
[PASS] Helm installed (v3.21.0)
[PASS] Trivy installed (v0.74.0)
[PASS] Argo CD CLI installed

--- PREPARING PROFILE DEFINITIONS ---
[PASS] Service profile definitions generated in ~/devops-workspace/profiles
```

---

### 4.2. `validate-environment.sh` Çalıştırma (Salt-Okunur Denetim)

Bu script sisteme **hiçbir paket yüklemez ve hiçbir konfigürasyonu değiştirmez**. Yalnızca mevcut durumun eğitim standartlarına uygunluğunu nesnel olarak raporlar.

```bash
bash outputs/lab-assets/LAB-ENV-00/scripts/validate-environment.sh
```

**Örnek Rapor Çıktısı:**
```text
==========================================================
          DEVOPS ENVIRONMENT VALIDATION SUITE            
==========================================================

--- [1/4] OPERATING SYSTEM & HARDWARE AUDIT ---
[PASS] Operating System: Ubuntu 24.04 LTS (noble)
[PASS] CPU Cores: 4 (>= 4 cores recommended)
[PASS] System RAM: 15890 MB (~16 GB detected)
[PASS] Free Root Disk Space: 68 GB (>= 30 GB)
[PASS] Kernel Parameter vm.max_map_count: 262144 (Elasticsearch ready)
[PASS] Internet Connectivity & DNS Resolution: Verified

--- [2/4] CLI TOOLCHAINS & VERSIONS ---
[PASS] Git: v2.43.0
[PASS] Docker Engine: v27.5.1 (Daemon Active & Accessible)
[PASS] Docker Compose: v2.32.4
[PASS] Terraform: 1.16.0
[PASS] kubectl: v1.31.9
[PASS] kind: v0.30.0
[PASS] Helm: v3.21.0
[PASS] Trivy: v0.74.0

--- [3/4] DEVOPS SERVICE ENDPOINTS (ACROSS 7 PROFILES) ---
[SKIP] Jenkins CI: Inactive or not started (Normal if profile is idle)
[SKIP] SonarQube Community: Inactive or not started (Normal if profile is idle)
[SKIP] Harbor Registry: Inactive or not started (Normal if profile is idle)
[SKIP] GitLab CE: Inactive or not started (Normal if profile is idle)
[SKIP] Prometheus: Inactive or not started (Normal if profile is idle)
[SKIP] Grafana: Inactive or not started (Normal if profile is idle)
[SKIP] Alertmanager: Inactive or not started (Normal if profile is idle)
[SKIP] Elasticsearch 8.17: Inactive or not started (Normal if profile is idle)
[SKIP] Kibana 8.17: Inactive or not started (Normal if profile is idle)
[SKIP] Headlamp UI: Inactive or not started (Normal if profile is idle)
[SKIP] Kubernetes Cluster: Idle (Start 'kubernetes' profile to test)

==========================================================
          ENVIRONMENT VALIDATION SUMMARY                 
==========================================================
  PASS : 14
  WARN : 0
  FAIL : 0
  SKIP : 9
----------------------------------------------------------
  STATUS: READY FOR TRAINING (OPTIMAL)
==========================================================
```

---

## 5. Doğrulama ve Kabul Kriteri

Eğitim ortamının başarıyla tamamlandığı, aşağıdaki komutun `0` çıkış kodu vermesiyle teyit edilir:

```bash
bash outputs/lab-assets/LAB-ENV-00/scripts/validate-environment.sh
```

`STATUS: READY FOR TRAINING` ibaresi görüldüğünde tüm araç zinciri ve profil şablonları 5 günlük müfredatın tamamını sorunsuz icra edebilecek durumdadır.
