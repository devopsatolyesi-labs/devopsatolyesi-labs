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
