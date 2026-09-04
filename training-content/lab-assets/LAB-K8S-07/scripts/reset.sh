#!/usr/bin/env bash
set -euo pipefail
kubectl delete deployment resilient-api --ignore-not-found=true
