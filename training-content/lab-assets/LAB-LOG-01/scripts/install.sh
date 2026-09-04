#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAB_DIR="${LAB_DIR:-${HOME}/devops-workspace/labs/LAB-LOG-01}"
COMPOSE=(sudo docker compose --project-directory "${LAB_DIR}" -f "${LAB_DIR}/compose.yaml")

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'HATA: %s\n' "$*" >&2; exit 1; }

if [[ "$(uname -s)" != "Linux" ]]; then
  die "Bu otomatik kurulum Ubuntu/Linux sunucusunda calistirilmalidir."
fi

log "Gerekli temel paketler denetleniyor"
missing=()
for command_name in curl jq; do
  command -v "${command_name}" >/dev/null 2>&1 || missing+=("${command_name}")
done
if ! command -v docker >/dev/null 2>&1; then
  missing+=(docker.io docker-compose-v2)
fi
if ((${#missing[@]} > 0)); then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates "${missing[@]}"
fi

sudo systemctl enable --now docker
sudo docker version >/dev/null
sudo docker compose version >/dev/null

log "Elasticsearch cekirdek parametresi kalici olarak ayarlaniyor"
printf 'vm.max_map_count=262144\n' | sudo tee /etc/sysctl.d/99-lab-log-01.conf >/dev/null
sudo sysctl --system >/dev/null

log "Lab dosyalari ${LAB_DIR} dizinine kuruluyor"
mkdir -p "${LAB_DIR}"
cp -a "${ASSET_DIR}/solution/." "${LAB_DIR}/"
mkdir -p "${LAB_DIR}/scripts" "${LAB_DIR}/runtime/nginx" "${LAB_DIR}/runtime/host-nginx"
cp -a "${ASSET_DIR}/scripts/." "${LAB_DIR}/scripts/"
chmod +x "${LAB_DIR}/scripts/"*.sh
printf '%s\n' "${ASSET_DIR}" >"${LAB_DIR}/.lab-source"

if sudo test -f /var/log/nginx/access.log; then
  printf 'HOST_NGINX_LOG_DIR=/var/log/nginx\n' >"${LAB_DIR}/.env"
  log "Sunucudaki gercek /var/log/nginx loglari toplama kapsamina alindi"
else
  printf 'HOST_NGINX_LOG_DIR=./runtime/host-nginx\n' >"${LAB_DIR}/.env"
  log "Native Nginx logu bulunamadi; lab Nginx loglari kullanilacak"
fi

log "Sabitlenmis container imajlari indiriliyor"
"${COMPOSE[@]}" pull

log "ELK servisleri baslatiliyor"
"${COMPOSE[@]}" up -d --force-recreate

wait_http() {
  local name="$1" url="$2" attempts="$3"
  for ((attempt=1; attempt<=attempts; attempt++)); do
    if curl --fail --silent "${url}" >/dev/null; then
      printf '[HAZIR] %s\n' "${name}"
      return 0
    fi
    printf '[BEKLE] %s (%d/%d)\n' "${name}" "${attempt}" "${attempts}"
    sleep 5
  done
  "${COMPOSE[@]}" ps
  die "${name} zaman asimina ugradi: ${url}"
}

wait_http "Elasticsearch" "http://localhost:9200/_cluster/health" 36
wait_http "Kibana" "http://localhost:5601/api/status" 48

log "ILM politikasi ve indeks sablonu yukleniyor"
curl --fail --silent --show-error -X PUT "http://localhost:9200/_ilm/policy/devops-nginx-7d" \
  -H 'Content-Type: application/json' \
  --data-binary "@${LAB_DIR}/elasticsearch/ilm-policy.json" | jq -e '.acknowledged == true' >/dev/null
curl --fail --silent --show-error -X PUT "http://localhost:9200/_index_template/devops-nginx-template" \
  -H 'Content-Type: application/json' \
  --data-binary "@${LAB_DIR}/elasticsearch/index-template.json" | jq -e '.acknowledged == true' >/dev/null

log "Kibana Data View olusturuluyor"
kibana_code="$(curl --silent --output /tmp/lab-log-01-kibana-response.json --write-out '%{http_code}' \
  -X POST 'http://localhost:5601/api/data_views/data_view' \
  -H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
  -d '{"data_view":{"id":"devops-nginx-logs","title":"devops-nginx-*","name":"Nginx Loglari","timeFieldName":"@timestamp","allowNoIndex":true},"override":true}')"
if [[ "${kibana_code}" != "200" && "${kibana_code}" != "409" ]]; then
  sed -n '1,20p' /tmp/lab-log-01-kibana-response.json >&2
  die "Kibana Data View olusturulamadi (HTTP ${kibana_code})."
fi
rm -f /tmp/lab-log-01-kibana-response.json

log "Dogrulama trafigi uretiliyor"
"${LAB_DIR}/scripts/generate-traffic.sh"
sleep 8

log "Uctan uca dogrulama calistiriliyor"
export LAB_DIR
"${LAB_DIR}/scripts/validate.sh"

printf '\nKurulum tamamlandi. Kibana: http://SUNUCU_IP:5601  Demo Nginx: http://SUNUCU_IP:8088\n'
