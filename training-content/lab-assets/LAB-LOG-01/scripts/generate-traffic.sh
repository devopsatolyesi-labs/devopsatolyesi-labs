#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${NGINX_URL:-http://localhost:8088}"

for path in / '/?campaign=devops-lab' /olmayan-sayfa /simulate/500; do
  curl --silent --output /dev/null \
    -H 'User-Agent: LAB-LOG-01-Traffic/1.0' \
    -H 'Referer: https://labs.devopsatolyesi.com/day5/' \
    "${BASE_URL}${path}"
done

printf 'Nginx uzerinde 200, 404 ve 500 durum kodlu test trafigi uretildi.\n'
