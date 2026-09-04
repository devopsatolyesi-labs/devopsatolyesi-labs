#!/usr/bin/env bash
set -euo pipefail
kubectl get storageclass lab-nfs >/dev/null
test "$(kubectl get pvc shared-data -n lab-k8s-15 -o jsonpath='{.status.phase}')" = Bound
pod="$(kubectl get pod -n lab-k8s-15 -l app=writers -o jsonpath='{.items[0].metadata.name}')"
test "$(kubectl exec -n lab-k8s-15 "$pod" -- sort -u /shared/writers.txt | wc -l | tr -d ' ')" -ge 2
