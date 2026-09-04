#!/usr/bin/env bash
kubectl delete -f service.yaml --ignore-not-found=true 2>/dev/null || true
echo "Cleanup completed for LAB-K8S-02."
