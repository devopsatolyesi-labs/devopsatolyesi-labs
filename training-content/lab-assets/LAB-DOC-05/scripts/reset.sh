#!/usr/bin/env bash
set -euo pipefail

echo "==> Resetting LAB-DOC-05..."
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$script_dir/cleanup.sh"
cp -a "$script_dir/../starter/." .
echo "Reset completed. Starter files restored."
