#!/usr/bin/env bash
set -euo pipefail
lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
echo "Resetting workspace for LAB-INC-01..."
bash "$lab_dir/scripts/cleanup.sh"
cp -r "$lab_dir/starter"/. .
echo "Workspace reset to starter state for LAB-INC-01."
