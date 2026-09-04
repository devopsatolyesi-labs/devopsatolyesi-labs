#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-DOC-18..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
if [ -d "$script_dir/../starter" ]; then
    cp -a "$script_dir/../starter/." .
fi
echo "Workspace reset for LAB-DOC-18."
