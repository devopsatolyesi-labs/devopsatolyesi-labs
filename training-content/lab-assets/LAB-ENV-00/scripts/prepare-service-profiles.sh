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
