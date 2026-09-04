#!/usr/bin/env bash
set -euo pipefail
kubectl delete deployment config-demo --ignore-not-found=true
kubectl delete configmap app-config --ignore-not-found=true
kubectl delete secret db-credentials --ignore-not-found=true
