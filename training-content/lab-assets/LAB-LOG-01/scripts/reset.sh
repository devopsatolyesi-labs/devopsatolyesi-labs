#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${LAB_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
ASSET_DIR="${ASSET_DIR:-}"
if [[ -z "${ASSET_DIR}" && -f "${LAB_DIR}/.lab-source" ]]; then
  ASSET_DIR="$(<"${LAB_DIR}/.lab-source")"
fi
if [[ ! -x "${ASSET_DIR}/scripts/install.sh" ]]; then
  printf 'HATA: Kaynak asset dizini bulunamadi. ASSET_DIR degiskenini LAB-LOG-01 paketine ayarlayin.\n' >&2
  exit 1
fi
"${SCRIPT_DIR}/cleanup.sh"
LAB_DIR="${LAB_DIR}" "${ASSET_DIR}/scripts/install.sh"
