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
