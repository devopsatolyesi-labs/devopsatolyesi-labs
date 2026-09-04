#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-06: Trivy Security Scan..."
grep -Eq -- '--severity([ =]+)CRITICAL' trivy-scan.sh || {
    echo "[FAIL] CRITICAL severity gate is missing." >&2
    exit 1
}
grep -Eq -- '--exit-code([ =]+)1' trivy-scan.sh || {
    echo "[FAIL] Blocking exit code is missing." >&2
    exit 1
}
grep -q -- '--ignore-unfixed' trivy-scan.sh || {
    echo "[FAIL] --ignore-unfixed is missing." >&2
    exit 1
}
bash trivy-scan.sh
echo "[PASS] Trivy blocking scan passed on hardened baseline image."
