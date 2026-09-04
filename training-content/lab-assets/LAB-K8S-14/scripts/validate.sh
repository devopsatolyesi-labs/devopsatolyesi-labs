#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl get pod accepted -n governed -o jsonpath='{.spec.containers[0].resources.requests.cpu}')" = 100m
test "$(kubectl get pod accepted -n governed -o jsonpath='{.spec.containers[0].resources.limits.memory}')" = 128Mi
test "$(kubectl get pod rejected -n governed --ignore-not-found)" = ""
kubectl get resourcequota team-budget -n governed >/dev/null
