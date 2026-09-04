#!/usr/bin/env bash
set -euo pipefail
test -f Dockerfile
test -f server.py
echo "[PASS] Dockerfile and server script exist."
