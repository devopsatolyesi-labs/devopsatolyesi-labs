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
