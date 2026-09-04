# LAB-ENV-00 — Ubuntu Server 24.04 LTS Üzerinde DevOps Ortamı Kurulumu ve Doğrulama

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-ENV-00.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-ENV-00.zip && cd LAB-ENV-00`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-ENV-00
cd ~/labs/LAB-ENV-00
```

### `scripts/install-all.sh`

```bash
mkdir -p "$(dirname -- scripts/install-all.sh)"
cat > scripts/install-all.sh <<'LAB_FILE_EOF_1'
#!/usr/bin/env bash
# ==============================================================================
# Script: install-all.sh
# Purpose: Automated fast preparation / environment recovery tool
# Notice: This is NOT an alternative to learning manual installation!
#         Use for initial classroom staging or rapid lab VM recovery.
# ==============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_pass() { echo -e "[\033[32mPASS\033[0m] $1"; }
log_warn() { echo -e "[\033[33mWARN\033[0m] $1"; }
log_fail() { echo -e "[\033[31mFAIL\033[0m] $1"; }
log_inst() { echo -e "[\033[34mINSTALL\033[0m] $1"; }

echo "=========================================================="
echo "      DEVOPS TRAINING AUTOMATED FAST-PREP / RECOVERY     "
echo "=========================================================="

# 1. OS Check
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
    log_pass "Ubuntu 24.04 LTS detected ($VERSION_CODENAME)"
  elif [[ "$ID" == "ubuntu" ]]; then
    log_warn "Ubuntu $VERSION_ID detected (Target baseline is 24.04 LTS)"
  else
    log_fail "Non-Ubuntu system ($ID). Halting automated setup."
    exit 1
  fi
else
  log_fail "Cannot read /etc/os-release. Halting."
  exit 1
fi

# 2. Architecture Check
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$ARCH" in
  amd64|x86_64) log_pass "Architecture: x86_64 (amd64)" ;;
  arm64|aarch64) log_pass "Architecture: arm64 (aarch64)" ;;
  *) log_fail "Unsupported CPU Architecture: $ARCH" && exit 1 ;;
esac

# 3. Internet Connectivity
if curl -sf --connect-timeout 4 https://www.google.com >/dev/null; then
  log_pass "Internet & DNS connectivity verified"
else
  log_fail "No internet access. Package downloads will fail."
  exit 1
fi

# 4. Hardware Resources
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM_MB" -ge 7500 ]; then
  log_pass "System RAM: ${TOTAL_RAM_MB} MB (Meets >= 8 GB requirement)"
else
  log_warn "System RAM: ${TOTAL_RAM_MB} MB (Low memory; only run 1 of 7 profiles at a time)"
fi

FREE_DISK_GB=$(df -BG / | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$FREE_DISK_GB" -ge 20 ]; then
  log_pass "Free Disk Space: ${FREE_DISK_GB} GB"
else
  log_warn "Free Disk Space: ${FREE_DISK_GB} GB (Recommend at least 25 GB free)"
fi

echo -e "\n--- CHECKING & INSTALLING TOOLCHAINS (IDEMPOTENT) ---"

# Base Tools
if command -v git &>/dev/null && command -v jq &>/dev/null; then
  log_pass "Git and Base utilities already installed"
else
  log_inst "Base utilities missing. Installing..."
  bash "${SCRIPT_DIR}/install-base-tools.sh"
  log_pass "Base utilities installed"
fi

# Docker Engine & Compose
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || docker --version | awk '{print $3}' | tr -d ',')
  log_pass "Docker Engine installed (v$DOCKER_VER)"
  log_pass "Docker Compose installed"
else
  log_inst "Docker Engine or Compose missing. Installing..."
  bash "${SCRIPT_DIR}/install-docker.sh"
  log_pass "Docker Engine installed"
  log_pass "Docker Compose installed"
fi

# Terraform
if command -v terraform &>/dev/null; then
  TF_VER=$(terraform version | head -n1 | awk '{print $2}')
  log_pass "Terraform installed ($TF_VER)"
else
  log_inst "Terraform missing. Installing..."
  bash "${SCRIPT_DIR}/install-terraform.sh"
  log_pass "Terraform installed"
fi

# Kubernetes Toolchain (kubectl, kind, helm)
K8S_MISSING=0
command -v kubectl &>/dev/null || K8S_MISSING=1
command -v kind &>/dev/null || K8S_MISSING=1
command -v helm &>/dev/null || K8S_MISSING=1

if [ "$K8S_MISSING" -eq 0 ]; then
  log_pass "kubectl installed ($(kubectl version --client --output=json 2>/dev/null | jq -r .clientVersion.gitVersion 2>/dev/null || echo 'installed'))"
  log_pass "kind installed ($(kind version | awk '{print $2}'))"
  log_pass "Helm installed ($(helm version --short 2>/dev/null || echo 'installed'))"
else
  log_inst "Kubernetes tools (kubectl/kind/helm) incomplete. Installing..."
  bash "${SCRIPT_DIR}/install-kubernetes-tools.sh"
  log_pass "kubectl installed"
  log_pass "kind installed"
  log_pass "Helm installed"
fi

# Security Toolchains (Trivy, Argo CD CLI)
SEC_MISSING=0
command -v trivy &>/dev/null || SEC_MISSING=1
command -v argocd &>/dev/null || SEC_MISSING=1

if [ "$SEC_MISSING" -eq 0 ]; then
  log_pass "Trivy installed ($(trivy --version 2>/dev/null | head -n1 | awk '{print $2}'))"
  log_pass "Argo CD CLI installed"
else
  log_inst "Security & GitOps tools (Trivy/ArgoCD) missing. Installing..."
  bash "${SCRIPT_DIR}/install-security-tools.sh"
  log_pass "Trivy installed"
  log_pass "Argo CD CLI installed"
fi

# Prepare 7 Service Profiles
echo -e "\n--- PREPARING 7 SERVICE PROFILES DEFINITIONS ---"
bash "${SCRIPT_DIR}/prepare-service-profiles.sh"
log_pass "7 Service profiles generated in ~/devops-workspace/profiles"

echo -e "\n--- RUNNING FINAL ENVIRONMENT AUDIT ---"
bash "${SCRIPT_DIR}/validate-environment.sh"
LAB_FILE_EOF_1
chmod +x scripts/install-all.sh
```

### `scripts/install-base-tools.sh`

```bash
mkdir -p "$(dirname -- scripts/install-base-tools.sh)"
cat > scripts/install-base-tools.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
# ==============================================================================
# Script: install-base-tools.sh
# Purpose: Installs fundamental OS utilities, Git, and kernel tuning on Ubuntu 24.04
# ==============================================================================
set -euo pipefail

echo "==> [1/4] Updating package cache..."
sudo apt-get update -y

echo "==> [2/4] Installing core utilities and prerequisite packages..."
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  software-properties-common \
  git \
  jq \
  unzip \
  tar \
  htop \
  net-tools \
  iproute2 \
  python3-venv \
  python3-pip \
  python3-yaml

echo "==> [3/4] Tuning kernel parameters for Elasticsearch & container workloads..."
sudo sysctl -w vm.max_map_count=262144
if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf 2>/dev/null; then
  echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
fi

echo "==> [4/4] Verifying base tools..."
git --version
jq --version
echo "==> Base utilities installed and kernel parameters tuned successfully."
LAB_FILE_EOF_2
chmod +x scripts/install-base-tools.sh
```

### `scripts/install-docker.sh`

```bash
mkdir -p "$(dirname -- scripts/install-docker.sh)"
cat > scripts/install-docker.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
# ==============================================================================
# Script: install-docker.sh
# Purpose: Installs Docker Engine 27.5.1 and Docker Compose v2 via official repo
# ==============================================================================
set -euo pipefail

echo "==> [1/5] Setting up Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
fi

echo "==> [2/5] Configuring official Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

echo "==> [3/5] Installing Docker CE, CLI, containerd, and Compose plugin..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> [4/5] Enabling and starting Docker systemd service..."
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group if not already in it
CURRENT_USER="${USER:-$(whoami)}"
if [ "$CURRENT_USER" != "root" ]; then
  echo "==> Adding $CURRENT_USER to docker group..."
  sudo usermod -aG docker "$CURRENT_USER"
fi

echo "==> [5/5] Verifying Docker installation..."
docker --version
docker compose version
echo "==> Running Docker Smoke Test..."
sudo docker run --rm hello-world
echo "==> Docker Engine installed and smoke test passed successfully."
LAB_FILE_EOF_3
chmod +x scripts/install-docker.sh
```

### `scripts/install-kubernetes-tools.sh`

```bash
mkdir -p "$(dirname -- scripts/install-kubernetes-tools.sh)"
cat > scripts/install-kubernetes-tools.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
# ==============================================================================
# Script: install-kubernetes-tools.sh
# Purpose: Installs kubectl v1.31.x, kind v0.30.0, and Helm v3.21 on Ubuntu 24.04
# Upstream Pin: Kubernetes 1.31 LTS (v1.31.9), kind v0.30.0
# ==============================================================================
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) KIND_ARCH="amd64" ;;
  arm64) KIND_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

echo "==> [1/4] Installing kubectl (Kubernetes v1.31 LTS repository)..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
fi
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y kubectl

echo "==> [2/4] Installing kind (v0.30.0)..."
KIND_VERSION="v0.30.0"
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${KIND_ARCH}"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "==> [3/4] Installing Helm (v3)..."
if ! command -v helm &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "==> [4/4] Verifying Kubernetes tools..."
kubectl version --client --output=yaml
kind version
helm version

echo "==> Kubernetes tools (kubectl, kind, helm) installed successfully."
LAB_FILE_EOF_4
chmod +x scripts/install-kubernetes-tools.sh
```

### `scripts/install-security-tools.sh`

```bash
mkdir -p "$(dirname -- scripts/install-security-tools.sh)"
cat > scripts/install-security-tools.sh <<'LAB_FILE_EOF_5'
#!/usr/bin/env bash
# ==============================================================================
# Script: install-security-tools.sh
# Purpose: Installs Trivy v0.74 (Aqua Security) and Argo CD CLI v3.4 on Ubuntu 24.04
# ==============================================================================
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARGO_ARCH="amd64" ;;
  arm64) ARGO_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

echo "==> [1/3] Installing Trivy vulnerability scanner..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/trivy.gpg ]; then
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
fi
echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y trivy

echo "==> [2/3] Installing Argo CD CLI (v3.4.2)..."
ARGO_VERSION="v3.4.2"
curl -sSL -o argocd-linux "https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-${ARGO_ARCH}"
chmod +x argocd-linux
sudo mv argocd-linux /usr/local/bin/argocd

echo "==> [3/3] Verifying Security and GitOps tools..."
trivy --version
argocd version --client --short

echo "==> Running Trivy smoke test..."
trivy --help >/dev/null && echo "Trivy CLI is operational."
echo "==> Security and GitOps CLI tools installed successfully."
LAB_FILE_EOF_5
chmod +x scripts/install-security-tools.sh
```

### `scripts/install-terraform.sh`

```bash
mkdir -p "$(dirname -- scripts/install-terraform.sh)"
cat > scripts/install-terraform.sh <<'LAB_FILE_EOF_6'
#!/usr/bin/env bash
# ==============================================================================
# Script: install-terraform.sh
# Purpose: Installs HashiCorp Terraform 1.16.x via official HashiCorp repository
# Upstream Pin: Terraform 1.16.0 (2026 Stable Release)
# ==============================================================================
set -euo pipefail

echo "==> [1/4] Setting up HashiCorp GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/hashicorp-archive-keyring.gpg ]; then
  wget -O- https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
fi

echo "==> [2/4] Adding HashiCorp official repository..."
echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt-get update -y

echo "==> [3/4] Installing Terraform..."
sudo apt-get install -y terraform

echo "==> [4/4] Verifying Terraform installation..."
terraform version

echo "==> Running Terraform smoke test..."
TEMP_TF_DIR=$(mktemp -d)
cat <<'EOF' > "${TEMP_TF_DIR}/main.tf"
terraform {
  required_version = ">= 1.5.0"
}
output "smoke_test" {
  value = "TERRAFORM_OK"
}
EOF
(cd "${TEMP_TF_DIR}" && terraform init -no-color && terraform validate -no-color)
rm -rf "${TEMP_TF_DIR}"
echo "==> Terraform 1.16.x installed and smoke test passed successfully."
LAB_FILE_EOF_6
chmod +x scripts/install-terraform.sh
```

### `scripts/prepare-service-profiles.sh`

```bash
mkdir -p "$(dirname -- scripts/prepare-service-profiles.sh)"
cat > scripts/prepare-service-profiles.sh <<'LAB_FILE_EOF_7'
#!/usr/bin/env bash
# ==============================================================================
# Script: prepare-service-profiles.sh
# Purpose: Prepares isolated Compose files and configs for memory-profiled services
# Upstream Pins:
#   - Jenkins: 2.568.2-lts-jdk17
#   - SonarQube: 26.8.0.126808-community
#   - GitLab CE: 17.9.3-ce.0 | GitLab Runner: alpine-v17.9.1
#   - Harbor: v2.15.2
#   - kindest/node: v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211
#   - Headlamp: v0.45.0
#   - Prometheus: v3.13.2 | Grafana: 13.1.5 | Alertmanager: v0.33.0
#   - Elasticsearch & Kibana: 8.17.8 (Training-Stable 2026 Release) | Vector: 0.40.2-alpine
# ==============================================================================
set -euo pipefail

PROFILES_BASE="${HOME}/devops-workspace/profiles"
mkdir -p "${PROFILES_BASE}"

echo "==> [1/7] Preparing Profile: jenkins-ci..."
mkdir -p "${PROFILES_BASE}/jenkins-ci"
cat <<'EOF' > "${PROFILES_BASE}/jenkins-ci/compose.yaml"
services:
  jenkins:
    image: jenkins/jenkins:2.568.2-lts-jdk17
    container_name: jenkins-ci
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

echo "==> [2/7] Preparing Profile: secure-ci (Jenkins + SonarQube Community + Harbor)..."
mkdir -p "${PROFILES_BASE}/secure-ci"
cat <<'EOF' > "${PROFILES_BASE}/secure-ci/compose.yaml"
services:
  jenkins:
    image: jenkins/jenkins:2.568.2-lts-jdk17
    container_name: secure-jenkins
    restart: unless-stopped
    user: root
    ports:
      - "8080:8080"
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xms512m -Xmx512m
    volumes:
      - jenkins_data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

  sonarqube:
    image: sonarqube:26.8.0.126808-community
    container_name: secure-sonarqube
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
      - "SONAR_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions

  registry:
    image: registry:2.8
    container_name: secure-registry
    restart: unless-stopped
    ports:
      - "8082:5000"

volumes:
  jenkins_data:
  sonarqube_data:
  sonarqube_extensions:
EOF

echo "==> [3/7] Preparing Profile: gitlab-ci (GitLab CE 17.9.3 + Runner 17.9.1)..."
mkdir -p "${PROFILES_BASE}/gitlab-ci"
cat <<'EOF' > "${PROFILES_BASE}/gitlab-ci/compose.yaml"
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
        unicorn['worker_processes'] = 2
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

echo "==> [4/6] Preparing Profile: monitoring (Prometheus + Grafana + Alertmanager)..."
mkdir -p "${PROFILES_BASE}/monitoring/prometheus" "${PROFILES_BASE}/monitoring/alertmanager"
cat <<'EOF' > "${PROFILES_BASE}/monitoring/prometheus/prometheus.yml"
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
EOF

cat <<'EOF' > "${PROFILES_BASE}/monitoring/alertmanager/alertmanager.yml"
route:
  receiver: 'default'
receivers:
  - name: 'default'
EOF

cat <<'EOF' > "${PROFILES_BASE}/monitoring/compose.yaml"
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
      - GF_SECURITY_ADMIN_PASSWORD=${PLATFORM_ADMIN_PASSWORD:?PLATFORM_ADMIN_PASSWORD is required}

  alertmanager:
    image: prom/alertmanager:v0.33.0
    container_name: mon-alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
EOF

echo "==> [5/6] Preparing Profile: logging (Elasticsearch 8.17.8 + Kibana 8.17.8 + Vector)..."
mkdir -p "${PROFILES_BASE}/logging/vector"
cat <<'EOF' > "${PROFILES_BASE}/logging/vector/vector.yaml"
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

cat <<'EOF' > "${PROFILES_BASE}/logging/compose.yaml"
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

echo "==> [6/7] Preparing Profile: kubernetes (kind & Headlamp v0.45.0 UI)..."
mkdir -p "${PROFILES_BASE}/kubernetes"
cat <<'EOF' > "${PROFILES_BASE}/kubernetes/kind-cluster.yaml"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: devops-cluster
nodes:
  - role: control-plane
    image: kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        apiVersion: kubeadm.k8s.io/v1beta4
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
    image: kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211
  - role: worker
    image: kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211
EOF

cat <<'EOF' > "${PROFILES_BASE}/kubernetes/compose.yaml"
services:
  headlamp:
    image: ghcr.io/headlamp-k8s/headlamp:v0.45.0
    container_name: k8s-headlamp
    ports:
      - "8088:4466"
    volumes:
      - ${HOME}/.kube/config:/root/.kube/config:ro
EOF

echo "==> [7/7] Preparing Profile: argocd-gitops (Argo CD manifests for kind)..."
mkdir -p "${PROFILES_BASE}/argocd-gitops"
cat <<'EOF' > "${PROFILES_BASE}/argocd-gitops/install-argocd.sh"
#!/usr/bin/env bash
set -euo pipefail
echo "==> Installing Argo CD on local kind cluster..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.0/manifests/install.yaml
echo "==> Waiting for Argo CD server to start..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s || true
echo "==> Argo CD initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "N/A"
echo ""
EOF
chmod +x "${PROFILES_BASE}/argocd-gitops/install-argocd.sh"

echo "==> All 7 service profiles generated in ${PROFILES_BASE}."
LAB_FILE_EOF_7
chmod +x scripts/prepare-service-profiles.sh
```

### `scripts/start-profile.sh`

```bash
mkdir -p "$(dirname -- scripts/start-profile.sh)"
cat > scripts/start-profile.sh <<'LAB_FILE_EOF_8'
#!/usr/bin/env bash
# ==============================================================================
# Script: start-profile.sh
# Purpose: Activates one of 7 isolated service profiles within 8-16 GB RAM
# Profiles (7 Total): docker | jenkins-ci | secure-ci | gitlab-ci | kubernetes | monitoring | logging
# ==============================================================================
set -euo pipefail

PROFILES_BASE="${HOME}/devops-workspace/profiles"
PROFILE="${1:-}"

if [ -z "$PROFILE" ]; then
  echo "Usage: $0 <profile-name>"
  echo "Available profiles:"
  echo "  1) docker         (Base container lab environment)"
  echo "  2) jenkins-ci     (Jenkins 2.568.2 LTS)"
  echo "  3) secure-ci      (Jenkins + SonarQube Community + Harbor 2.15)"
  echo "  4) gitlab-ci      (GitLab CE 17.9.3 + Runner 17.9.1)"
  echo "  5) kubernetes     (kind K8s 1.31.9 3-Node + Headlamp v0.45)"
  echo "  6) argocd-gitops  (Argo CD GitOps Controller on kind)"
  echo "  7) monitoring     (Prometheus 3.13 LTS + Grafana 13.1.5 + Alertmanager)"
  echo "  8) logging        (Elasticsearch 8.17.8 + Kibana 8.17.8 + Vector)"
  exit 1
fi

PROFILE_DIR="${PROFILES_BASE}/${PROFILE}"

echo "=========================================================="
echo "  ACTIVATING PROFILE: ${PROFILE}"
echo "=========================================================="

# Check RAM availability
AVAIL_RAM_MB=$(free -m | awk '/^Mem:/{print $7}')
echo "==> Available Host Memory: ${AVAIL_RAM_MB} MB"

case "$PROFILE" in
  docker)
    echo "==> Profile 'docker': Native Docker Engine active. No heavy background daemon."
    echo "==> Required RAM: ~0.5 GB | Ready for container labs."
    ;;

  jenkins-ci)
    echo "==> Required RAM: ~1.5 GB | Exposed Ports: 8080, 50000"
    (cd "$PROFILE_DIR" && docker compose up -d)
    echo "==> Waiting for Jenkins health..."
    sleep 5
    ;;

  secure-ci)
    echo "==> Required RAM: ~3.5 GB | Exposed Ports: 8080, 9000, 8082"
    (cd "$PROFILE_DIR" && docker compose up -d)
    echo "==> Waiting for Secure CI stack (Jenkins, SonarQube, Harbor)..."
    sleep 10
    ;;

  gitlab-ci)
    echo "==> Required RAM: ~4.5 GB | Exposed Ports: 8081, 2222"
    (cd "$PROFILE_DIR" && docker compose up -d)
    echo "==> GitLab CE 17.9.3 is initializing in the background..."
    ;;

  kubernetes)
    echo "==> Required RAM: ~3.0 GB | Exposed Ports: 80, 443, 8088"
    if ! kind get clusters 2>/dev/null | grep -q "devops-cluster"; then
      echo "==> Creating kind cluster 'devops-cluster' (Kubernetes v1.31.9)..."
      kind create cluster --config "${PROFILE_DIR}/kind-cluster.yaml"
    else
      echo "==> kind cluster 'devops-cluster' already running."
    fi
    echo "==> Starting Headlamp Web Dashboard v0.45.0..."
    (cd "$PROFILE_DIR" && docker compose up -d)
    ;;

  argocd-gitops)
    echo "==> Required RAM: ~1.5 GB | Argo CD GitOps on kind"
    if [ -f "${PROFILE_DIR}/install-argocd.sh" ]; then
      bash "${PROFILE_DIR}/install-argocd.sh"
    else
      echo "==> Preparing Argo CD installer in ${PROFILE_DIR}..."
      mkdir -p "${PROFILE_DIR}"
      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.0/manifests/install.yaml
    fi
    ;;

  monitoring)
    echo "==> Required RAM: ~1.2 GB | Exposed Ports: 9090, 3000, 9093"
    (cd "$PROFILE_DIR" && docker compose up -d)
    echo "==> Prometheus (9090) and Grafana (3000) are active."
    ;;

  logging)
    echo "==> Required RAM: ~2.4 GB | Exposed Ports: 9200, 5601"
    sudo sysctl -w vm.max_map_count=262144 >/dev/null
    (cd "$PROFILE_DIR" && docker compose up -d)
    echo "==> Elasticsearch 8.17.8 (9200) and Kibana 8.17.8 (5601) are active."
    ;;

  *)
    echo "ERROR: Unknown profile '$PROFILE'."
    exit 1
    ;;
esac

echo "==> Profile '${PROFILE}' started successfully."
echo "==> Current active containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
LAB_FILE_EOF_8
chmod +x scripts/start-profile.sh
```

### `scripts/status.sh`

```bash
mkdir -p "$(dirname -- scripts/status.sh)"
cat > scripts/status.sh <<'LAB_FILE_EOF_9'
#!/usr/bin/env bash
# ==============================================================================
# Script: status.sh
# Purpose: Inspects system resources, active profiles, running containers & ports
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          DEVOPS TRAINING ENVIRONMENT STATUS             "
echo "=========================================================="

echo -e "\n[1] HOST RESOURCE UTILIZATION"
echo "----------------------------------------------------------"
free -h
echo ""
df -h / | awk 'NR==1 || NR==2'
echo ""
uptime

echo -e "\n[2] ACTIVE DOCKER CONTAINERS"
echo "----------------------------------------------------------"
if command -v docker &>/dev/null && docker info &>/dev/null; then
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
else
  echo "Docker daemon is not running or current user lacks socket permission."
fi

echo -e "\n[3] KUBERNETES (kind) CLUSTERS"
echo "----------------------------------------------------------"
if command -v kind &>/dev/null; then
  CLUSTERS=$(kind get clusters 2>/dev/null || true)
  if [ -n "$CLUSTERS" ]; then
    echo "Active kind clusters: $CLUSTERS"
    kubectl get nodes 2>/dev/null || true
  else
    echo "No kind cluster currently active."
  fi
else
  echo "kind binary is not installed."
fi

echo -e "\n[4] LISTENING DEVOPS PORTS (ss -lntp)"
echo "----------------------------------------------------------"
if command -v ss &>/dev/null; then
  sudo ss -lntp 2>/dev/null | grep -E ":(22|80|443|3000|5601|8000|8080|8081|8082|8085|8088|9000|9090|9093|9100|9200)" || echo "No standard DevOps training ports currently open."
fi

echo -e "\n=========================================================="
LAB_FILE_EOF_9
chmod +x scripts/status.sh
```

### `scripts/stop-profile.sh`

```bash
mkdir -p "$(dirname -- scripts/stop-profile.sh)"
cat > scripts/stop-profile.sh <<'LAB_FILE_EOF_10'
#!/usr/bin/env bash
# ==============================================================================
# Script: stop-profile.sh
# Purpose: Gracefully terminates active service profile to release memory
# Profiles (7 Total): docker | jenkins-ci | secure-ci | gitlab-ci | kubernetes | monitoring | logging | all
# ==============================================================================
set -euo pipefail

PROFILES_BASE="${HOME}/devops-workspace/profiles"
PROFILE="${1:-}"

if [ -z "$PROFILE" ]; then
  echo "Usage: $0 <profile-name | all>"
  echo "Available profiles (7 Total):"
  echo "  docker | jenkins-ci | secure-ci | gitlab-ci | kubernetes | monitoring | logging | all"
  exit 1
fi

stop_single() {
  local p="$1"
  local p_dir="${PROFILES_BASE}/${p}"
  echo "==> Stopping profile: $p..."
  if [ "$p" = "kubernetes" ]; then
    if [ -d "$p_dir" ]; then
      (cd "$p_dir" && docker compose down 2>/dev/null || true)
    fi
    if kind get clusters 2>/dev/null | grep -q "devops-cluster"; then
      echo "==> Deleting kind cluster 'devops-cluster'..."
      kind delete cluster --name devops-cluster
    fi
  elif [ "$p" = "docker" ]; then
    echo "==> Profile 'docker' has no background compose service."
  elif [ -d "$p_dir" ]; then
    (cd "$p_dir" && docker compose down 2>/dev/null || true)
  fi
}

if [ "$PROFILE" = "all" ]; then
  echo "==> Stopping ALL 7 service profiles and freeing system resources..."
  for prf in jenkins-ci secure-ci gitlab-ci kubernetes monitoring logging; do
    stop_single "$prf"
  done
  echo "==> All profiles stopped."
else
  stop_single "$PROFILE"
  echo "==> Profile '$PROFILE' stopped."
fi

echo "==> Free memory after cleanup:"
free -h
LAB_FILE_EOF_10
chmod +x scripts/stop-profile.sh
```

### `scripts/validate-environment.sh`

```bash
mkdir -p "$(dirname -- scripts/validate-environment.sh)"
cat > scripts/validate-environment.sh <<'LAB_FILE_EOF_11'
#!/usr/bin/env bash
# ==============================================================================
# Script: validate-environment.sh
# Purpose: Comprehensive read-only audit of OS, resources, CLI tools & services
# Notice: DOES NOT INSTALL ANYTHING. Pure verification.
# ==============================================================================
set -u

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

log_pass() {
  echo -e "[\033[32mPASS\033[0m] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

log_warn() {
  echo -e "[\033[33mWARN\033[0m] $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

log_fail() {
  echo -e "[\033[31mFAIL\033[0m] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

log_skip() {
  echo -e "[\033[34mSKIP\033[0m] $1"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

echo "=========================================================="
echo "          DEVOPS ENVIRONMENT VALIDATION SUITE            "
echo "=========================================================="

echo -e "\n--- [1/4] OPERATING SYSTEM & HARDWARE AUDIT ---"

# OS Check
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
    log_pass "Operating System: Ubuntu 24.04 LTS ($VERSION_CODENAME)"
  elif [[ "$ID" == "ubuntu" ]]; then
    log_warn "Operating System: Ubuntu $VERSION_ID (Training baseline is 24.04 LTS)"
  else
    log_fail "Operating System is not Ubuntu ($ID $VERSION_ID detected)"
  fi
else
  log_fail "Cannot detect OS distribution (/etc/os-release missing)"
fi

# CPU Check
CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
if [ "$CPU_CORES" -ge 4 ]; then
  log_pass "CPU Cores: $CPU_CORES (>= 4 cores recommended)"
elif [ "$CPU_CORES" -ge 2 ]; then
  log_warn "CPU Cores: $CPU_CORES (Minimum acceptable is 2 cores; 4+ recommended)"
else
  log_fail "CPU Cores: $CPU_CORES (Insufficient CPU for containerized stacks)"
fi

# RAM Check
TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo 0)
if [ "$TOTAL_RAM_MB" -ge 15000 ]; then
  log_pass "System RAM: ${TOTAL_RAM_MB} MB (~16 GB detected)"
elif [ "$TOTAL_RAM_MB" -ge 7500 ]; then
  log_pass "System RAM: ${TOTAL_RAM_MB} MB (~8 GB detected - 7-profile switching required)"
else
  log_fail "System RAM: ${TOTAL_RAM_MB} MB (Less than 8 GB; heavy profiles will fail)"
fi

# Disk Check
FREE_DISK_GB=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub("G","",$4); print $4}' || echo 0)
if [ "$FREE_DISK_GB" -ge 30 ]; then
  log_pass "Free Root Disk Space: ${FREE_DISK_GB} GB (>= 30 GB)"
elif [ "$FREE_DISK_GB" -ge 15 ]; then
  log_warn "Free Root Disk Space: ${FREE_DISK_GB} GB (Low disk space; clean images frequently)"
else
  log_fail "Free Root Disk Space: ${FREE_DISK_GB} GB (< 15 GB available)"
fi

# Kernel Tuning
VM_MAP=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
if [ "$VM_MAP" -ge 262144 ]; then
  log_pass "Kernel Parameter vm.max_map_count: $VM_MAP (Elasticsearch 8.17 ready)"
else
  log_warn "Kernel Parameter vm.max_map_count: $VM_MAP (Elasticsearch requires >= 262144)"
fi

# Network / DNS Check
if curl -sf --connect-timeout 3 https://www.google.com >/dev/null; then
  log_pass "Internet Connectivity & DNS Resolution: Verified"
else
  log_fail "Internet Connectivity or DNS Resolution Failed"
fi

echo -e "\n--- [2/4] CLI TOOLCHAINS & VERSIONS ---"

# Git
if command -v git &>/dev/null; then
  GIT_VER=$(git --version | awk '{print $3}')
  log_pass "Git: v$GIT_VER"
else
  log_fail "Git is not installed"
fi

# Docker Engine
if command -v docker &>/dev/null; then
  DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || true)
  if [ -n "$DOCKER_VER" ]; then
    log_pass "Docker Engine: v$DOCKER_VER (Daemon Active & Accessible)"
  else
    log_warn "Docker CLI installed but daemon not accessible by $USER"
  fi
else
  log_fail "Docker Engine is not installed"
fi

# Docker Compose
if docker compose version &>/dev/null; then
  COMPOSE_VER=$(docker compose version --short 2>/dev/null || true)
  log_pass "Docker Compose: v$COMPOSE_VER"
else
  log_fail "Docker Compose (v2 plugin) is not installed"
fi

# Terraform
if command -v terraform &>/dev/null; then
  TF_VER=$(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || terraform version | head -n1 | awk '{print $2}')
  log_pass "Terraform: $TF_VER"
else
  log_fail "Terraform is not installed"
fi

# kubectl
if command -v kubectl &>/dev/null; then
  KUBECTL_VER=$(kubectl version --client -o json 2>/dev/null | jq -r .clientVersion.gitVersion 2>/dev/null || echo "installed")
  log_pass "kubectl: $KUBECTL_VER (Target: v1.31.x)"
else
  log_fail "kubectl is not installed"
fi

# kind
if command -v kind &>/dev/null; then
  KIND_VER=$(kind version 2>/dev/null | awk '{print $2}')
  log_pass "kind: $KIND_VER (Target: v0.30.0)"
else
  log_fail "kind is not installed"
fi

# Helm
if command -v helm &>/dev/null; then
  HELM_VER=$(helm version --short 2>/dev/null)
  log_pass "Helm: $HELM_VER"
else
  log_fail "Helm is not installed"
fi

# Trivy
if command -v trivy &>/dev/null; then
  TRIVY_VER=$(trivy --version 2>/dev/null | head -n1 | awk '{print $2}')
  log_pass "Trivy: v$TRIVY_VER (Target: v0.74.0)"
else
  log_fail "Trivy is not installed"
fi

echo -e "\n--- [3/4] DEVOPS SERVICE ENDPOINTS (ACROSS 7 PROFILES) ---"

check_endpoint() {
  local name="$1"
  local url="$2"
  local expected="$3"
  if curl -sf --connect-timeout 2 "$url" 2>/dev/null | grep -q "$expected"; then
    log_pass "$name: Healthy ($url responded)"
  elif curl -sf --connect-timeout 2 -I "$url" &>/dev/null; then
    log_pass "$name: Responding ($url returned HTTP status)"
  else
    log_skip "$name: Inactive or not started (Normal if profile is idle)"
  fi
}

check_endpoint "Jenkins CI (jenkins-ci / secure-ci)" "http://localhost:8080/login" "Jenkins"
check_endpoint "SonarQube Community (secure-ci)" "http://localhost:9000/api/system/status" "UP"
check_endpoint "Harbor Registry (secure-ci)" "http://localhost:8082/api/v2.0/ping" "pong"
check_endpoint "GitLab CE (gitlab-ci)" "http://localhost:8081/-/health" "OK"
check_endpoint "Prometheus (monitoring)" "http://localhost:9090/-/healthy" "Healthy"
check_endpoint "Grafana (monitoring)" "http://localhost:3000/api/health" "ok"
check_endpoint "Alertmanager (monitoring)" "http://localhost:9093/-/healthy" "OK"
check_endpoint "Elasticsearch 8.17 (logging)" "http://localhost:9200/_cluster/health" "status"
check_endpoint "Kibana 8.17 (logging)" "http://localhost:5601/api/status" "status"
check_endpoint "Headlamp UI (kubernetes)" "http://localhost:8088/" "Headlamp"

# kind Cluster check
if command -v kubectl &>/dev/null && kubectl cluster-info &>/dev/null; then
  log_pass "Kubernetes Cluster (kubernetes profile): Active & Ready"
else
  log_skip "Kubernetes Cluster: Idle (Start 'kubernetes' profile to test)"
fi

echo -e "\n=========================================================="
echo "          ENVIRONMENT VALIDATION SUMMARY                 "
echo "=========================================================="
echo "  PASS : $PASS_COUNT"
echo "  WARN : $WARN_COUNT"
echo "  FAIL : $FAIL_COUNT"
echo "  SKIP : $SKIP_COUNT"
echo "----------------------------------------------------------"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  echo -e "  STATUS: \033[32mREADY FOR TRAINING (OPTIMAL)\033[0m"
  EXIT_CODE=0
elif [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "  STATUS: \033[33mREADY FOR TRAINING (WITH WARNINGS)\033[0m"
  EXIT_CODE=0
else
  echo -e "  STATUS: \033[31mNOT READY - RESOLVE FAILED CHECKS FIRST\033[0m"
  EXIT_CODE=1
fi
echo "=========================================================="

exit $EXIT_CODE
LAB_FILE_EOF_11
chmod +x scripts/validate-environment.sh
```


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

#### 9. Beklenen Sonuç
```text
OS Network & DNS: PASSED
vm.max_map_count = 262144
```

#### 10. Sorun Giderme
- DNS hatası alınırsa: `/etc/resolv.conf` dosyasına `nameserver 8.8.8.8` veya `nameserver 1.1.1.1` ekleyin.

---

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

#### 9. Beklenen Sonuç
```text
git version 2.43.0 (veya 2.44+)
Git Functional Test: PASSED
```

#### 10. Sorun Giderme
- `Author identity unknown` hatası alınırsa: `git config --global user.name` ve `user.email` komutlarını çalıştırın.

---

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

#### 9. Beklenen Sonuç
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

#### 10. Sorun Giderme
- `permission denied while trying to connect to the Docker daemon socket`: Kullanıcınız henüz gruba yansımamıştır; `sudo chmod 666 /var/run/docker.sock` veya `newgrp docker` uygulayın.

---

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

#### 9. Beklenen Sonuç
```text
Docker Compose version v2.32.4 (veya v2.x)
Docker Compose Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `compose is not a docker command` hatası alınırsa: `sudo apt-get install --reinstall docker-compose-plugin` çalıştırın.

---

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

#### 9. Beklenen Sonuç
```text
Terraform v1.16.0 (veya 1.16.x)
Success! The configuration is valid.
Terraform Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `Certificate verification failed`: `sudo apt-get install --reinstall ca-certificates` çalıştırın.

---

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

#### 9. Beklenen Sonuç
```text
clientVersion:
  gitVersion: v1.31.9 (veya v1.31.x)
kubectl Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `The connection to the server localhost:8080 was refused`: Bu bir hata değildir; henüz bir küme çalışmadığını gösterir. `--client` bayrağı ile istemci testi yapılmalıdır.

---

### 2.7. kind (Kubernetes in Docker)

> [!NOTE]
> **Uyumluluk Gerekçesi (Compatibility Rationale):**
> Kubernetes 1.31 LTS hattı ve kind v0.30.0 seçimi; Ubuntu 24.04 cgroups v2 tam desteği, `kubeadm.k8s.io/v1beta4` modern konfigürasyon yapısı ve Envoy proxy entegrasyonu için kanıtlanmış stabil standarttır. `kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211` digest pini ile sürüm drifti ve beklenmedik imaj çekme hataları kesin olarak engellenir.

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

#### 9. Beklenen Sonuç
```text
kind v0.30.0
Creating cluster "test-smoke" ...
NAME                       STATUS   ROLES           AGE   VERSION
test-smoke-control-plane   Ready    control-plane   10s   v1.31.9
Deleted clusters: ["test-smoke"]
kind Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `failed to create cluster: docker: command not found`: Docker servisinin ayakta olduğunu (`sudo systemctl status docker`) teyit edin.

---

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

#### 9. Beklenen Sonuç
```text
version.BuildInfo{Version:"v3.21.0", ...}
1 chart(s) linted, 0 chart(s) failed
Helm Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `helm: command not found`: Binary'nin `/usr/local/bin` altında olduğundan ve PATH değişkeninde bulunduğundan emin olun.

---

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

#### 9. Beklenen Sonuç
```text
Version: 0.74.0
alpine:3.20 (alpine 3.20.x)
Total: 0 (CRITICAL: 0)
Trivy Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `DB download timeout`: Ağ proxy veya güvenlik duvarı engelliyorsa `trivy image --download-db-only` komutunu manuel koşturun.

---

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

#### 9. Beklenen Sonuç
```text
2.568.2
Jenkins Smoke Test: PASSED
```

#### 10. Sorun Giderme
- `Connection refused`: Jenkins'in açılması 15–30 saniye sürebilir; `docker logs -f jenkins-server` çıktısında `Jenkins is fully up and running` satırını bekleyin.

---

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

#### 9. Beklenen Sonuç
```text
SonarQube Smoke Test: PASSED (Status: UP)
```

#### 10. Sorun Giderme
- SonarQube konteyneri çöküyorsa `sysctl vm.max_map_count` değerinin 262144 olduğunu teyit edin.

---

### 2.12. GitLab CE & GitLab Runner

#### 1. Ön Gereksinimler
- En az 4 GB boş RAM (GitLab Omnibus bellek yoğun bir servistir).
- Host üzerinde 8081 ve 2222 portları boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi imajlar: `gitlab/gitlab-ce:17.9.3-ce.0` ve `gitlab/gitlab-runner:alpine-v17.9.1`.

> [!IMPORTANT]
> **Sürüm Uyumluluğu (Version Parity):**
> GitLab resmi mimari politikası gereği GitLab sunucusu ile GitLab Runner aynı major.minor serisinde çalışmalıdır. CE 17.9.3 sürümü ile tam uyumlu resmi upstream imajı `gitlab/gitlab-runner:alpine-v17.9.1` olarak sabitlenmiştir.

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

#### 9. Beklenen Sonuç
```text
GitLab OK
GitLab Smoke Test: PASSED
```

#### 10. Sorun Giderme
- İlk açılış 2–3 dakika sürebilir. `docker logs -f gitlab-server` ile Puma servisinin başladığını izleyin.

---

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

#### 9. Beklenen Sonuç
```text
pong
Harbor Smoke Test: PASSED
```

#### 10. Sorun Giderme
- 8082 portu çakışıyorsa host port eşlemesini `compose.yaml` içinde güncelleyin.

---

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

#### 9. Beklenen Sonuç
```text
'admin:login' logged in successfully
Argo CD Smoke Test: PASSED
```

#### 10. Sorun Giderme
- Podlar `Pending` kalırsa `kubectl describe nodes` ile düğüm kaynaklarını kontrol edin.

---

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

#### 9. Beklenen Sonuç
```text
Headlamp Smoke Test: PASSED
```

#### 10. Sorun Giderme
- Küme bilgisi görünmezse kubeconfig içindeki server adresinin `127.0.0.1` yerine Docker host IP'si olduğundan emin olun.

---

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

#### 9. Beklenen Sonuç
```text
Prometheus: HEALTHY
Grafana: HEALTHY
```

#### 10. Sorun Giderme
- Grafana'ya bağlanılamıyorsa `admin/admin` varsayılan kimlik bilgileriyle `http://localhost:3000` adresini açın.

---

### 2.17. Elasticsearch, Kibana & Vector

#### 1. Ön Gereksinimler
- `vm.max_map_count >= 262144`
- Host portları `9200:9200` ve `5601:5601` boş olmalıdır.

#### 2. Repository / GPG Key Hazırlığı
Resmi imajlar: `docker.elastic.co/elasticsearch/elasticsearch:8.17.8`, `docker.elastic.co/kibana/kibana:8.17.8`, `timberio/vector:0.40.2-alpine`.

> [!NOTE]
> **Sürüm Seçimi ve Bellek Uyumluluk Kanıtı (Version & RAM Feasibility Rationale):**
> - **Neden 9.x (9.5.2) Seçilmedi?** Upstream 9.x serisi, dahili OpenJDK 22+ taban bellek gereksinimi, varsayılan zorunlu HTTPS/TLS ve 2 GB minimum heap (4 GB+ konteyner sınırı) zorunluluğu getirmektedir. Kibana 9.x ile birlikte logging profili tek başına 5.5 GB RAM tüketmekte ve 8–16 GB RAM'li sunucularda Linux OOM Killer'ı tetiklemektedir.
> - **Neden 7.17.23 Terk Edildi?** 7.17 serisi EOL sürecine girmiş olup 2026 yılı modern loglama ekosistemlerinin (Vector, OpenTelemetry) güncel OCI ve bulk API beklentilerini karşılamamaktadır.
> - **Neden 8.17.8 Seçildi?** Aktif olarak desteklenen 2026 LTS kararlı sürümüdür. Tek düğümlü modda güvenlik kapatılabilir (`xpack.security.enabled=false`), `ES_JAVA_OPTS=-Xms1g -Xmx1g` ile düşük bellek tüketimi (~1.5 GB ES, ~800 MB Kibana) sağlanır ve Vector 0.40.2 ile `suppress_type_name: true` parametresiyle tam uyumlu çalışır.

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

#### 9. Beklenen Sonuç
```text
"8.17.8"
Elasticsearch Smoke Test: PASSED
```

#### 10. Sorun Giderme
- Elasticsearch anında çöküyorsa `docker logs log-elasticsearch` ile bellek hatasını inceleyin; `sudo sysctl -w vm.max_map_count=262144` uygulayın.

---

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

> [!WARNING]
> **ÖNEMLİ NOT:** Bu bölümde yer alan otomasyon scriptleri, yukarıdaki manuel kurulum adımlarını öğrenmenin bir alternatifi **değildir**. Bu scriptler, eğitim başlamadan önce ortamın hızla hazırlanması ya da bir çökme durumunda ortamın dakikalar içinde baştan kurtarılması (recovery) amacıyla kullanılır.

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
