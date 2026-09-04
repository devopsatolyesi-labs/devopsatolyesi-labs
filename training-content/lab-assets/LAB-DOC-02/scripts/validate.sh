#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-DOC-02: Volumes & Environment..."
export LAB_POSTGRES_PASSWORD=${LAB_POSTGRES_PASSWORD:-training-only-password}
project=lab-doc-02
cleanup() {
    docker compose -p "$project" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker compose -p "$project" config --quiet
docker compose -p "$project" up -d --wait
docker compose -p "$project" exec -T database \
    psql -U devops -d training -v ON_ERROR_STOP=1 -c \
    "CREATE TABLE IF NOT EXISTS lab_events(name text); TRUNCATE lab_events; INSERT INTO lab_events VALUES ('volume-ok');" \
    >/dev/null

first_container=$(docker compose -p "$project" ps -q database)
docker compose -p "$project" rm -sf database >/dev/null
docker compose -p "$project" up -d --wait
second_container=$(docker compose -p "$project" ps -q database)
row_count=$(docker compose -p "$project" exec -T database \
    psql -U devops -d training -tAc "SELECT count(*) FROM lab_events WHERE name='volume-ok';")

if [[ "$first_container" == "$second_container" || "$row_count" != "1" ]]; then
    echo "[FAIL] LAB-DOC-02 container recreation or persisted row check failed." >&2
    exit 1
fi
echo "[PASS] LAB-DOC-02 volume persistence verified."
