#!/usr/bin/env bash
set -euo pipefail

echo "==> Validating LAB-DOC-13 production Compose patterns..."
project=lab-doc-13
export POSTGRES_DB=${POSTGRES_DB:-order_db}
export POSTGRES_USER=${POSTGRES_USER:-order_user}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-training-only-password}
export GATEWAY_PORT=${GATEWAY_PORT:-8080}
compose=(docker compose -p "$project" -f compose.yaml -f compose.prod.yaml)
cleanup() { "${compose[@]}" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

"${compose[@]}" config --quiet
"${compose[@]}" up -d --build --wait

response=$(curl --fail --silent "http://localhost:${GATEWAY_PORT}/healthz")
if ! echo "$response" | grep -q '"status":"HEALTHY"' || \
   ! echo "$response" | grep -q '"database":"CONNECTED"' || \
   ! echo "$response" | grep -q '"cache":"CONNECTED"'; then
  echo "[FAIL] Gateway did not prove API, database and cache health: $response" >&2
  exit 1
fi

postgres_container=$("${compose[@]}" ps -q postgres-db)
redis_container=$("${compose[@]}" ps -q redis-broker)
postgres_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "5432/tcp")}}' "$postgres_container")
redis_binding=$(docker inspect --format '{{json (index .NetworkSettings.Ports "6379/tcp")}}' "$redis_container")
if [[ "$postgres_binding" != "null" || "$redis_binding" != "null" ]]; then
  echo "[FAIL] PostgreSQL or Redis is exposed to the host." >&2
  exit 1
fi

profiles=$(docker compose -f compose.yaml --profile worker --profile monitoring config --services)
grep -qx 'queue-worker' <<<"$profiles"
grep -qx 'redis-exporter' <<<"$profiles"
echo "[PASS] LAB-DOC-13 health, isolation, profiles and production overrides verified."
