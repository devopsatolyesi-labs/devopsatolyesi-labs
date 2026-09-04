#!/usr/bin/env bash
set -euo pipefail
helm status headlamp -n headlamp >/dev/null
kubectl rollout status deployment/headlamp -n headlamp --timeout=120s
test "$(kubectl auth can-i list pods --all-namespaces --as=system:serviceaccount:headlamp:headlamp-viewer)" = yes
test "$(kubectl auth can-i delete pods --all-namespaces --as=system:serviceaccount:headlamp:headlamp-viewer)" = no
test "$(kubectl auth can-i get secrets --all-namespaces --as=system:serviceaccount:headlamp:headlamp-viewer)" = no
