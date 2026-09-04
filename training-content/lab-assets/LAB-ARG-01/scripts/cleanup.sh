#!/usr/bin/env bash
kubectl delete -f application.yaml --ignore-not-found=true 2>/dev/null || true
echo "Cleanup completed for LAB-ARG-01."
