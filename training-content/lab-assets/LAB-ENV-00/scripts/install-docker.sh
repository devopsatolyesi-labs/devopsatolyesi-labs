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
