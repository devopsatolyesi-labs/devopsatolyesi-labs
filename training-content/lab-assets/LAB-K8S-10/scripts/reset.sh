#!/usr/bin/env bash
set -euo pipefail
helm uninstall my-release --ignore-not-found || true
