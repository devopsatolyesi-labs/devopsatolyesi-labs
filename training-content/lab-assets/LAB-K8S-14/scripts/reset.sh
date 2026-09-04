#!/usr/bin/env bash
set -euo pipefail
kubectl delete namespace governed --ignore-not-found=true
