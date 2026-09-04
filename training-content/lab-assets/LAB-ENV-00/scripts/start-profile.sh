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
