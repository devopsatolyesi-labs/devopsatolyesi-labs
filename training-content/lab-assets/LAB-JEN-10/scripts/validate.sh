#!/usr/bin/env bash
set -euo pipefail
test -f Dockerfile
echo "[PASS] Security gate Dockerfile exists."
