#!/usr/bin/env bash
set -euo pipefail
test -f Jenkinsfile
echo "[PASS] Declarative Jenkinsfile exists."
