# Prometheus & Grafana Monitoring Stack Kurulumu

Bu rehber, sistem ve container metriklerini toplamak, sorgulamak (PromQL) ve görselleştirmek için **Prometheus** ve **Grafana** bileşenlerinin kurulumunu adım adım açıklar.

---

## 1. Docker Compose ile Hızlı Monitoring Stack Kurulumu

```bash
mkdir -p ~/monitoring-stack
cd ~/monitoring-stack

cat <<'EOF' > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

cat <<'EOF' > docker-compose.yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.50.0
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prom_data:/prometheus
    ports:
      - "9090:9090"

  node-exporter:
    image: prom/node-exporter:v1.7.0
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"

  grafana:
    image: grafana/grafana:10.3.3
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  prom_data:
  grafana_data:
EOF

docker compose up -d
```

---

## 2. Kubernetes Üzerinde kube-prometheus-stack (Helm) Kurulumu

Production standardında Prometheus Operator, Alertmanager, Grafana ve Node Exporter kurulumu:

```bash
# Prometheus Community Helm deposunu ekleyin
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Values dosyasını oluşturun
cat <<'EOF' > kube-prom-values.yaml
grafana:
  adminPassword: "admin"
  service:
    type: NodePort
    nodePort: 30300

prometheus:
  service:
    type: NodePort
    nodePort: 30900
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
EOF

# Kurulumu gerçekleştirin
helm install kube-stack prometheus-community/kube-prometheus-stack   --namespace monitoring --create-namespace   -f kube-prom-values.yaml

# Pod durumlarını kontrol edin
kubectl get pods -n monitoring
```
