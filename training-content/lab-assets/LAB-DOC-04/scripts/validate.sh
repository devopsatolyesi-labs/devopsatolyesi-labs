#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-04: Multi-stage Hardening..."
stage_count=$(grep -Ec '^[[:space:]]*FROM[[:space:]]+' Dockerfile)
if [[ "$stage_count" -lt 2 ]]; then
    echo "[FAIL] Expected at least two Dockerfile stages, found $stage_count." >&2
    exit 1
fi
docker build -t lab-doc-04-hardened:latest . >/dev/null
configured_user=$(docker image inspect lab-doc-04-hardened:latest --format '{{.Config.User}}')
runtime_user=$(docker run --rm --entrypoint id lab-doc-04-hardened:latest -u)
if [[ "$configured_user" == "10001" && "$runtime_user" == "10001" ]]; then
    echo "[PASS] Multi-stage image executes as non-root user 10001."
    exit 0
else
    echo "[FAIL] Expected configured/runtime UID 10001, found '$configured_user'/'$runtime_user'." >&2
    exit 1
fi
