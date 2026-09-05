#!/usr/bin/env bash
set -euo pipefail
kubectl get pv lab-k8s-08-local-pv -o jsonpath='{.status.phase}' | grep -qx Bound
kubectl get pvc app-data -n lab-k8s-08 -o jsonpath='{.status.phase}' | grep -qx Bound
kubectl exec -n lab-k8s-08 writer -- test -s /data/evidence.txt
echo "[PASS] Static PV/PVC binding and persistence verified."
