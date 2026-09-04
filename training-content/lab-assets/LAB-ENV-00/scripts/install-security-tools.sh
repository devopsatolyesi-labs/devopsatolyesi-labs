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
