#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-DOC-02..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
cp -a "$script_dir/../starter/." .
echo "Workspace reset to starter state for LAB-DOC-02."
