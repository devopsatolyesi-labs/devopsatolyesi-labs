#!/usr/bin/env bash
set -euo pipefail

mode=${1:-check}
repository_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
content_dir="$repository_root/training-content"
manifest="$content_dir/SHA256SUMS"
temporary_manifest=$(mktemp)
trap 'rm -f "$temporary_manifest"' EXIT

(
  cd "$content_dir"
  if command -v sha256sum >/dev/null 2>&1; then
    find . -type f ! -name SHA256SUMS ! -name '*.pyc' ! -path '*/__pycache__/*' ! -path '*/target/*' -exec sha256sum {} + | LC_ALL=C sort -k 2
  else
    find . -type f ! -name SHA256SUMS ! -name '*.pyc' ! -path '*/__pycache__/*' ! -path '*/target/*' -exec shasum -a 256 {} + | LC_ALL=C sort -k 2
  fi
) > "$temporary_manifest"

case "$mode" in
  update)
    mv "$temporary_manifest" "$manifest"
    trap - EXIT
    echo "Training content checksum manifest updated."
    ;;
  check)
    if ! cmp -s "$temporary_manifest" "$manifest"; then
      diff -u "$manifest" "$temporary_manifest" || true
      echo "Training content checksum manifest is stale. Run: scripts/training-checksums.sh update" >&2
      exit 1
    fi
    echo "Training content checksum manifest: PASS"
    ;;
  *)
    echo "Usage: training-checksums.sh {check|update}" >&2
    exit 64
    ;;
esac
