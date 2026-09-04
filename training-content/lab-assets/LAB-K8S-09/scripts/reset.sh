#!/usr/bin/env bash
set -euo pipefail
kubectl delete ingress web-ingress --ignore-not-found=true
kubectl delete deployment service-blue --ignore-not-found=true
kubectl delete service service-blue --ignore-not-found=true
