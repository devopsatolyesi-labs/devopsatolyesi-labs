#!/usr/bin/env bash
set -euo pipefail

echo "==> Validating LAB-DOC-05 Multi-Tier Compose Stack..."
export LAB_POSTGRES_PASSWORD=${LAB_POSTGRES_PASSWORD:-training-only-password}
project=lab-doc-05
cleanup() { docker compose -p "$project" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker compose -p "$project" config --quiet
docker compose -p "$project" up -d --build --wait
health=$(curl --fail --silent http://localhost:8080/healthz)
first=$(curl --fail --silent http://localhost:8080/ | jq -r .page_hits_from_redis)
second=$(curl --fail --silent http://localhost:8080/ | jq -r .page_hits_from_redis)

if ! echo "$health" | jq -e '.status == "HEALTHY" and .db == "OK" and .redis == "OK"' >/dev/null; then
  echo "[FAIL] API did not prove PostgreSQL and Redis connectivity: $health" >&2
  exit 1
fi
if [[ "$second" -ne $((first + 1)) ]]; then
  echo "[FAIL] Redis counter did not increment: $first -> $second" >&2
  exit 1
fi
postgres_container=$(docker compose -p "$project" ps -q postgres-db)
redis_container=$(docker compose -p "$project" ps -q redis-cache)
postgres_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "5432/tcp")}}' "$postgres_container")
redis_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "6379/tcp")}}' "$redis_container")
if [[ "$postgres_binding" != "null" || "$redis_binding" != "null" ]]; then
  echo "[FAIL] A data service port is exposed on the host." >&2
  exit 1
fi
echo "[PASS] LAB-DOC-05 API, PostgreSQL, Redis and network isolation verified."
