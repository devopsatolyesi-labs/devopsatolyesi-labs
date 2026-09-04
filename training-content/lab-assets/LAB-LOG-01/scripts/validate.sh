#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="${LAB_DIR:-${HOME}/devops-workspace/labs/LAB-LOG-01}"
COMPOSE=(sudo docker compose --project-directory "${LAB_DIR}" -f "${LAB_DIR}/compose.yaml")
failures=0

pass() { printf '[PASS] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; failures=$((failures + 1)); }

if [[ "$(sysctl -n vm.max_map_count)" -ge 262144 ]]; then
  pass "vm.max_map_count Elasticsearch icin yeterli"
else
  fail "vm.max_map_count en az 262144 olmali"
fi

for service in elasticsearch logstash kibana nginx; do
  container_id="$("${COMPOSE[@]}" ps -q "${service}")"
  if [[ -n "${container_id}" ]] && [[ "$(sudo docker inspect -f '{{.State.Health.Status}}' "${container_id}")" == "healthy" ]]; then
    pass "${service} healthy"
  else
    fail "${service} healthy degil"
  fi
done

if [[ "$("${COMPOSE[@]}" ps --status running -q filebeat | wc -l | tr -d ' ')" == "1" ]]; then
  pass "filebeat calisiyor"
else
  fail "filebeat calismiyor"
fi

if curl --fail --silent http://localhost:9200/_cluster/health | jq -e '.status == "green" or .status == "yellow"' >/dev/null; then
  pass "Elasticsearch API erisilebilir"
else
  fail "Elasticsearch API erisilemiyor"
fi

doc_count="$(curl --silent 'http://localhost:9200/devops-nginx-*/_count' | jq -r '.count // 0')"
parsed_count="$(curl --silent 'http://localhost:9200/devops-nginx-*/_count?q=tags:nginx_access_parsed' | jq -r '.count // 0')"
failure_count="$(curl --silent 'http://localhost:9200/devops-nginx-*/_count?q=tags:_grok_nginx_access_failure' | jq -r '.count // 0')"
status_500_count="$(curl --silent 'http://localhost:9200/devops-nginx-*/_count?q=http.response.status_code:500' | jq -r '.count // 0')"

if [[ "${doc_count}" -gt 0 ]]; then pass "${doc_count} Nginx log belgesi indekslendi"; else fail "Indekslenmis Nginx logu yok"; fi
if [[ "${parsed_count}" -gt 0 ]]; then pass "${parsed_count} access logu alanlara ayrildi"; else fail "Parse edilmis access logu yok"; fi
if [[ "${failure_count}" -eq 0 ]]; then pass "Grok access parse hatasi yok"; else fail "${failure_count} access logu parse edilemedi"; fi
if [[ "${status_500_count}" -gt 0 ]]; then pass "HTTP 500 olayi aranabilir durumda"; else fail "HTTP 500 olayi bulunamadi"; fi

if curl --fail --silent http://localhost:5601/api/data_views/data_view/devops-nginx-logs \
  -H 'kbn-xsrf: true' | jq -e '.data_view.title == "devops-nginx-*"' >/dev/null; then
  pass "Kibana Nginx Loglari Data View hazir"
else
  fail "Kibana Data View bulunamadi"
fi

if ((failures > 0)); then
  printf '\nVALIDATION FAILED: %d kontrol basarisiz.\n' "${failures}" >&2
  exit 1
fi

printf '\nVALIDATION SUCCESS: Nginx -> Filebeat -> Logstash -> Elasticsearch -> Kibana zinciri calisiyor.\n'
