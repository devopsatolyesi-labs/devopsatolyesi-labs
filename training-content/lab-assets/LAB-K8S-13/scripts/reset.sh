#!/usr/bin/env bash
set -euo pipefail
helm uninstall headlamp -n headlamp --ignore-not-found
kubectl delete clusterrolebinding headlamp-viewer --ignore-not-found=true
kubectl delete clusterrole headlamp-viewer --ignore-not-found=true
kubectl delete namespace headlamp --ignore-not-found=true
