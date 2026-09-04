#!/usr/bin/env bash
set -euo pipefail
mkdir -p build_output
echo "Build v${BUILD_NUMBER:-1}" > build_output/info.txt
