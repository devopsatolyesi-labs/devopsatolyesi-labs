#!/usr/bin/env bash
set -euo pipefail
kubectl delete deployment catalog-service --ignore-not-found=true
kubectl delete service catalog-svc --ignore-not-found=true
