#!/usr/bin/env bash
set -euo pipefail
umask 077

solution_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
env_file="$solution_dir/.env"

command -v openssl >/dev/null 2>&1 || {
  echo "openssl is required to generate the lab database credential." >&2
  exit 1
}

if [[ ! -f $env_file ]]; then
  password=$(openssl rand -hex 24)
  sed "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${password}/" \
    "$solution_dir/.env.example" > "$env_file"
  chmod 600 "$env_file"
fi

docker compose --project-directory "$solution_dir" --env-file "$env_file" \
  -f "$solution_dir/compose.yaml" up --detach --build --wait
