#!/usr/bin/env bash
kubectl delete -f fixed-deployment.yaml --ignore-not-found=true 2>/dev/null || true
echo "Cleanup completed for LAB-INC-01."
