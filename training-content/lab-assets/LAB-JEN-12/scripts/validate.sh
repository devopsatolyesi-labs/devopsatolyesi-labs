#!/usr/bin/env bash
set -euo pipefail
test -f k8s-deployment.yaml
echo "[PASS] Kubernetes deployment manifest exists."
