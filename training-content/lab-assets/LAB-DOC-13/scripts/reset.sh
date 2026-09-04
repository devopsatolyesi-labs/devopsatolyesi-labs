#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
echo "==> Cleaning existing containers..."
bash "$script_dir/cleanup.sh"
echo "==> Restoring starter templates to the current directory..."
cp -a "$script_dir/../starter/." .
echo "==> LAB-DOC-13 reset completed."
