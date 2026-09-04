#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="${LAB_DIR:-${HOME}/devops-workspace/labs/LAB-LOG-01}"
sudo docker compose --project-directory "${LAB_DIR}" -f "${LAB_DIR}/compose.yaml" down --volumes --remove-orphans
printf 'LAB-LOG-01 konteynerleri, agi ve Docker volume verileri kaldirildi. Lab dosyalari korundu.\n'
