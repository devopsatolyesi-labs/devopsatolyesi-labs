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
