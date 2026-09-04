# LAB-LOG-01 — 2026 ELK Yığını: Nginx Loglarını Uçtan Uca Merkezileştirme

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-LOG-01.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-LOG-01.zip && cd LAB-LOG-01`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-LOG-01
cd ~/labs/LAB-LOG-01
```

### `starter/README.md`

```bash
mkdir -p "$(dirname -- starter/README.md)"
cat > starter/README.md <<'LAB_FILE_EOF_1'
# LAB-LOG-01 başlangıç paketi

`sample/nginx-access.log`, GCP eğitim platformundaki gerçek Nginx `combined`
formatından alınmış anonimleştirilmiş bir örnektir. Uygulama sırasında bu satırı
alanlara ayıran Logstash filtresi oluşturulur. Tam çalışan dosyalar `solution/`,
otomasyon ve kabul testleri `scripts/` altındadır.
LAB_FILE_EOF_1
```

### `starter/sample/nginx-access.log`

```bash
mkdir -p "$(dirname -- starter/sample/nginx-access.log)"
cat > starter/sample/nginx-access.log <<'LAB_FILE_EOF_2'
127.0.0.1 - - [01/Sep/2026:16:06:58 +0300] "GET /elk-log-probe?source=cockpit HTTP/2.0" 401 172 "-" "DevOps-Lab-ELK-Probe/1.0"
LAB_FILE_EOF_2
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="${LAB_DIR:-${HOME}/devops-workspace/labs/LAB-LOG-01}"
sudo docker compose --project-directory "${LAB_DIR}" -f "${LAB_DIR}/compose.yaml" down --volumes --remove-orphans
printf 'LAB-LOG-01 konteynerleri, agi ve Docker volume verileri kaldirildi. Lab dosyalari korundu.\n'
LAB_FILE_EOF_3
chmod +x scripts/cleanup.sh
```

### `scripts/generate-traffic.sh`

```bash
mkdir -p "$(dirname -- scripts/generate-traffic.sh)"
cat > scripts/generate-traffic.sh <<'LAB_FILE_EOF_4'
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
LAB_FILE_EOF_4
chmod +x scripts/generate-traffic.sh
```

### `scripts/install.sh`

```bash
mkdir -p "$(dirname -- scripts/install.sh)"
cat > scripts/install.sh <<'LAB_FILE_EOF_5'
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
LAB_FILE_EOF_5
chmod +x scripts/install.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_6'
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
LAB_FILE_EOF_6
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_7'
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
LAB_FILE_EOF_7
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## 1. Lab Senaryosu

Nginx `access.log` dosyası aşağıdaki gibi düz metin üretir:

```text
127.0.0.1 - - [01/Sep/2026:16:06:58 +0300] "GET /elk-log-probe?source=cockpit HTTP/2.0" 401 172 "-" "DevOps-Lab-ELK-Probe/1.0"
```

Bu satır insan tarafından okunabilir; ancak “son 15 dakikadaki 500 hataları”, “en çok çağrılan URL” veya “HTTP/2 kullanan istemciler” gibi sorular için kayıt alanlara ayrılmalıdır.

Tek Ubuntu sunucusunda tam log veri hattı kurulacaktır. Filebeat hem lab Nginx loglarını hem de sunucuda varsa gerçek `/var/log/nginx` kayıtlarını izler. Logstash, GCP eğitim platformunda gözlenen gerçek Nginx `combined` biçimine göre satırları ayrıştırır. Elasticsearch belgeleri indeksler; Kibana arama ve görselleştirme arayüzünü sağlar.

Bu temel lab tamamen manuel yapılır. Öğrenci hazır kurulum veya sıfırlama betiği çalıştırmaz; Compose, Filebeat, Logstash, Nginx, ILM ve Kibana Data View adımlarını tek tek uygular.

## 2. Amaç

- Filebeat `filestream` ile dosya tabanlı Nginx loglarını takip etmek.
- Grok ile düz metni `client.ip`, `http.request.method`, `url.original` ve `http.response.status_code` alanlarına ayırmak.
- Parse hatalarını `_grok_nginx_access_failure` etiketiyle görünür kılmak.
- Elasticsearch mapping, index template ve ILM görevlerini açıklamak.
- Kibana Discover ve KQL ile HTTP 4xx/5xx olaylarını aramak.
- Persistent Queue ve Dead Letter Queue'nun veri kaybını nasıl azalttığını açıklamak.

### Temel terimler

| Terim | Türkçe açıklama |
|---|---|
| **Event / Olay** | Veri hattından geçen tek log kaydı. |
| **Shipper / Taşıyıcı** | Logu kaynağından okuyup ileten hafif ajan; burada Filebeat. |
| **Pipeline / Veri hattı** | Logstash input, filter ve output aşamaları. |
| **Grok** | Düz metni kalıplarla yapısal alanlara ayıran filtre. |
| **Document / Belge** | Elasticsearch'te JSON olarak saklanan tek kayıt. |
| **Index / İndeks** | Benzer belgelerin mantıksal koleksiyonu. |
| **Mapping** | Alanların `ip`, `integer`, `keyword`, `date` gibi tiplerini tanımlayan şema. |
| **Data View** | Kibana'nın görüntüleyeceği indeks deseni. |
| **KQL** | Kibana Query Language; alan tabanlı arama dili. |
| **ILM** | Index Lifecycle Management; indeks saklama yaşam döngüsü. |
| **Persistent Queue** | Logstash olaylarını geçici kesintilerde diskte bekleten kuyruk. |
| **DLQ** | Reddedilen sorunlu olayların incelenmek üzere ayrıldığı Dead Letter Queue. |

## 3. Mimari / Akış

```text
                     Tek Ubuntu Sunucu

  Gerçek Nginx                     Lab Nginx :8088
  /var/log/nginx                   ./runtime/nginx
         |                               |
         +---------------+---------------+
                         v
              Filebeat 8.17 filestream
                         |
                         v  Beats :5044 (Docker ağı)
              Logstash 8.17 Pipeline
              Grok + Date + User Agent + GeoIP
              Persistent Queue + DLQ
                         |
                         v
        Elasticsearch — devops-nginx-YYYY.MM.dd
              mapping + 7 günlük ILM
                         |
              +----------+----------+
              |                     |
       REST API :9200         Kibana :5601
       yalnız localhost       Discover + KQL
```

Elasticsearch, Logstash ve Kibana birlikte **ELK** adını oluşturur. Filebeat eklendiğinde dosyadan başlayan log toplama hattı tamamlanır.

## 4. Ön Koşullar

- Ubuntu 24.04, en az 4 vCPU, 8 GB RAM ve 15 GB boş disk
- `sudo` yetkisi ve internet erişimi
- `5601`, `8088`, `9200` portlarının boş olması
- Eğitim repo paketinin standart dizinde bulunması

Cockpit terminalinde preflight çalıştırın:

```bash
free -h
df -h /
sudo ss -lntp | grep -E ':(5601|8088|9200)\b' || true
test -d ~/devops-workspace/devops-practitioner-egitim-katalogu/outputs/lab-assets/LAB-LOG-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Paketleri ve çekirdek ayarını elle hazırlayın

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl jq docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo sysctl -w vm.max_map_count=262144
printf 'vm.max_map_count=262144\n' | sudo tee /etc/sysctl.d/99-lab-log-01.conf
mkdir -p ~/labs/LAB-LOG-01/{filebeat,logstash/config,logstash/pipeline,elasticsearch,nginx/html,runtime/nginx,runtime/host-nginx}
cd ~/labs/LAB-LOG-01
```

### Adım 2 — Yapılandırma dosyalarını tek tek oluşturun

Her dosyayı `nano` ile açın ve bağlantıdaki içeriği terminale yapıştırın. Hazır kurulum betiği kullanmayın:

- `nano compose.yaml` → [`compose.yaml`](../lab-assets/LAB-LOG-01/solution/compose.yaml)
- `nano filebeat/filebeat.yml` → [`filebeat.yml`](../lab-assets/LAB-LOG-01/solution/filebeat/filebeat.yml)
- `nano logstash/config/logstash.yml` → [`logstash.yml`](../lab-assets/LAB-LOG-01/solution/logstash/config/logstash.yml)
- `nano logstash/config/pipelines.yml` → [`pipelines.yml`](../lab-assets/LAB-LOG-01/solution/logstash/config/pipelines.yml)
- `nano logstash/pipeline/nginx.conf` → [`nginx.conf`](../lab-assets/LAB-LOG-01/solution/logstash/pipeline/nginx.conf)
- `nano elasticsearch/ilm-policy.json` → [`ilm-policy.json`](../lab-assets/LAB-LOG-01/solution/elasticsearch/ilm-policy.json)
- `nano elasticsearch/index-template.json` → [`index-template.json`](../lab-assets/LAB-LOG-01/solution/elasticsearch/index-template.json)
- `nano nginx/default.conf` → [`default.conf`](../lab-assets/LAB-LOG-01/solution/nginx/default.conf)
- `nano nginx/html/index.html` → [`index.html`](../lab-assets/LAB-LOG-01/solution/nginx/html/index.html)

Native Nginx varsa gerçek log dizinini, yoksa boş lab dizinini elle seçin:

```bash
if sudo test -r /var/log/nginx/access.log; then
  printf 'HOST_NGINX_LOG_DIR=/var/log/nginx\n' > .env
else
  printf 'HOST_NGINX_LOG_DIR=./runtime/host-nginx\n' > .env
fi
```

YAML, JSON ve Logstash söz dizimini elle doğrulayın:

```bash
docker compose config
jq . elasticsearch/ilm-policy.json >/dev/null
jq . elasticsearch/index-template.json >/dev/null
docker compose run --rm logstash \
  /usr/share/logstash/bin/logstash --config.test_and_exit \
  -f /usr/share/logstash/pipeline/nginx.conf
```

### Adım 3 — Servisleri elle başlatın

```bash
cd ~/labs/LAB-LOG-01
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
sudo docker stats --no-stream
```

GCP 8 GB testinde yaklaşık tüketim Elasticsearch 1.58 GiB, Logstash 0.88 GiB, Kibana 0.58 GiB, Filebeat 0.05 GiB ve Nginx 0.01 GiB olmuştur. Bu profil diğer ağır profillerle aynı anda çalıştırılmamalıdır.

### Adım 4 — ILM ve index template'i elle yükleyin

```bash
curl --fail -X PUT http://localhost:9200/_ilm/policy/devops-nginx-7d \
  -H 'Content-Type: application/json' --data-binary @elasticsearch/ilm-policy.json
curl --fail -X PUT http://localhost:9200/_index_template/devops-nginx-template \
  -H 'Content-Type: application/json' --data-binary @elasticsearch/index-template.json
```

### Adım 5 — Data View'u arayüzden elle oluşturun

Kibana'da **Stack Management → Data Views → Create data view** yolunu izleyin:

- Name: `Nginx Logları`
- Index pattern: `devops-nginx-*`
- Timestamp field: `@timestamp`

Bu temel labda Data View veya dashboard API ile otomatik oluşturulmaz.

Tam Compose: [`../lab-assets/LAB-LOG-01/solution/compose.yaml`](../lab-assets/LAB-LOG-01/solution/compose.yaml)

### Adım 6 — Nginx log kaynağını doğrulayın

```bash
curl -s http://localhost:8088/ >/dev/null
curl -s http://localhost:8088/olmayan-sayfa >/dev/null
curl -s http://localhost:8088/test-500 >/dev/null
sudo tail -n 4 ~/labs/LAB-LOG-01/runtime/nginx/access.log
cat ~/labs/LAB-LOG-01/.env
```

Beklenen loglar `200`, `404` ve `500` durum kodlarını içerir. Native Nginx varsa `.env` içinde şu değer görülür:

```text
HOST_NGINX_LOG_DIR=/var/log/nginx
```

Native Nginx yoksa boş bir lab dizini kullanılır; lab Nginx kaynağı çalışmaya devam eder.

### Adım 7 — Filebeat yapılandırmasını inceleyin

```bash
sed -n '1,220p' ~/labs/LAB-LOG-01/filebeat/filebeat.yml
```

Tam dosya: [`../lab-assets/LAB-LOG-01/solution/filebeat/filebeat.yml`](../lab-assets/LAB-LOG-01/solution/filebeat/filebeat.yml)

Dört benzersiz `filestream` input, lab/host access ve error loglarını okur. `fingerprint.length: 64`, küçük lab dosyalarının hemen izlenmesini sağlar. Yalnız düz metin `access.log` ve `access.log.1` seçilir; `.gz` dosyaları metinmiş gibi okunmaz.

### Adım 8 — Gerçek Nginx biçimine göre Grok filtresini inceleyin

```bash
sed -n '1,240p' ~/labs/LAB-LOG-01/logstash/pipeline/nginx.conf
```

Tam dosya: [`../lab-assets/LAB-LOG-01/solution/logstash/pipeline/nginx.conf`](../lab-assets/LAB-LOG-01/solution/logstash/pipeline/nginx.conf)

| Ham bölüm | Elasticsearch alanı | Tip |
|---|---|---|
| `127.0.0.1` | `client.ip` | `ip` |
| `GET` | `http.request.method` | `keyword` |
| `/path?query=1` | `url.original` | `wildcard` |
| `HTTP/2.0` | `http.version` | `keyword` |
| `401` | `http.response.status_code` | `integer` |
| byte sayısı | `http.response.body.bytes` | `long` |

`500+` için `event.outcome: failure` ve `incident_candidate` eklenir. Eşleşmeyen access kayıtları atılmaz; `_grok_nginx_access_failure` etiketiyle görünür kalır.

### Adım 9 — Persistent Queue, DLQ ve ILM'yi inceleyin

```bash
cat ~/labs/LAB-LOG-01/logstash/config/logstash.yml
jq . ~/labs/LAB-LOG-01/elasticsearch/ilm-policy.json
jq . ~/labs/LAB-LOG-01/elasticsearch/index-template.json
curl -s http://localhost:9200/_ilm/policy/devops-nginx-7d | jq .
```

Tam dosyalar:

- [`logstash.yml`](../lab-assets/LAB-LOG-01/solution/logstash/config/logstash.yml)
- [`ilm-policy.json`](../lab-assets/LAB-LOG-01/solution/elasticsearch/ilm-policy.json)
- [`index-template.json`](../lab-assets/LAB-LOG-01/solution/elasticsearch/index-template.json)

Eğitim profilinde indeksler yedi gün sonra silinir; küçük öğrenci diskinin kontrolsüz log büyümesiyle dolması önlenir.

### Adım 10 — Elasticsearch aramaları yapın

```bash
curl -s 'http://localhost:9200/_cat/indices/devops-nginx-*?v'
```

Kaynak başına belge sayısı:

```bash
curl -s -H 'Content-Type: application/json' \
  'http://localhost:9200/devops-nginx-*/_search' \
  -d '{"size":0,"aggs":{"sources":{"terms":{"field":"service.name"}}}}' \
  | jq '.aggregations.sources.buckets'
```

HTTP 500 olayları:

```bash
curl -s -H 'Content-Type: application/json' \
  'http://localhost:9200/devops-nginx-*/_search' \
  -d '{
    "size": 5,
    "query": {"term":{"http.response.status_code":500}},
    "sort": [{"@timestamp":"desc"}],
    "_source": ["@timestamp","service.name","client.ip","http.request.method","url.original","http.response.status_code","event.outcome","tags"]
  }' | jq '.hits.hits[]._source'
```

### Adım 11 — Kibana Discover ve KQL kullanın

Merkezi GCP gösterimi için `https://elk1.devopsatolyesi.com`, kendi öğrenci sunucunuz için `http://SUNUCU_IP:5601` adresini açın. **Analytics → Discover** ekranında **Nginx Logları** Data View'unu seçin ve zaman aralığını **Last 15 minutes** yapın.

```text
http.response.status_code >= 500
```

```text
service.name: "host-nginx" and http.version: "2.0"
```

```text
tags: "_grok_nginx_access_failure"
```

Son sorgu sıfır sonuç döndürmelidir.

## 6. Beklenen Sonuç

GCP testinde `host-nginx` kaynağından 138, `lab-nginx` kaynağından 37 belge işlendi. Gerçek host HTTP/2 kaydı şu yapıya dönüştü:

```json
{
  "client": {"ip":"172.68.224.148"},
  "http": {
    "request":{"method":"GET"},
    "response":{"status_code":200},
    "version":"2.0"
  },
  "service":{"name":"host-nginx"},
  "tags":["nginx_access_parsed"]
}
```

Sayılar trafiğe göre değişir; alan yapısı ve sıfır Grok hatası kabul kriteridir.

## 7. Doğrulama

```bash
cd ~/labs/LAB-LOG-01
curl -s http://localhost:8088/ >/dev/null
curl -s http://localhost:8088/test-500 >/dev/null
sleep 8
sudo docker compose ps
curl -s http://localhost:9200/_cluster/health | jq -r .status
curl -s http://localhost:9200/devops-nginx-*/_count | jq .count
curl -s -H 'Content-Type: application/json' \
  http://localhost:9200/devops-nginx-*/_count \
  -d '{"query":{"term":{"http.response.status_code":500}}}' | jq .count
curl -s -H 'Content-Type: application/json' \
  http://localhost:9200/devops-nginx-*/_count \
  -d '{"query":{"term":{"tags":"_grok_nginx_access_failure"}}}' | jq .count
```

Kabul kriterleri: dört servis `healthy`, Filebeat `running`, indeks ve parse edilmiş belge sayısı sıfırdan büyük, Grok access hatası sıfır, HTTP 500 aranabilir ve Kibana Data View mevcut.

## 8. Sorun Giderme

### Elasticsearch: `vm.max_map_count is too low`

```bash
sudo sysctl -w vm.max_map_count=262144
printf 'vm.max_map_count=262144\n' | sudo tee /etc/sysctl.d/99-lab-log-01.conf
```

### Logstash sağlıklı değil

```bash
cd ~/labs/LAB-LOG-01
sudo docker compose logs --tail=100 logstash
sudo docker compose run --rm logstash \
  /usr/share/logstash/bin/logstash --config.test_and_exit \
  -f /usr/share/logstash/pipeline/nginx.conf
```

### Grok hatası var

```bash
curl -s -H 'Content-Type: application/json' \
  'http://localhost:9200/devops-nginx-*/_search' \
  -d '{"size":5,"query":{"term":{"tags":"_grok_nginx_access_failure"}},"_source":["message","service.name"]}' \
  | jq '.hits.hits[]._source'
```

`.gz` rotasyon dosyalarını düz metin input'a eklemeyin. Farklı `log_format` varsa Grok kalıbını varsaymak yerine gerçek örnek satıra göre güncelleyin.

### Kibana Discover boş

```bash
curl -s http://localhost:9200/devops-nginx-*/_count | jq .count
curl -s http://localhost:5601/api/data_views/data_view/devops-nginx-logs \
  -H 'kbn-xsrf: true' | jq '.data_view.title'
```

Zaman aralığını genişletin ve `Nginx Logları` Data View'unu seçin.

## 9. Temizlik / Sıfırlama

```bash
cd ~/labs/LAB-LOG-01
sudo docker compose down
```

Yalnız laba ait konteyner, ağ ve volume verileri silinir; host `/var/log/nginx` dosyaları korunur.

Lab volume verilerini de silmek için önce doğru dizinde olduğunuzu doğrulayın:

```bash
pwd
sudo docker compose down -v
```

## 10. Production Notu

- Labdaki `xpack.security.enabled=false` üretimde kullanılmaz; TLS, kimlik doğrulama ve en az yetkili RBAC zorunludur.
- Elasticsearch REST portu internete açılmaz. Labda dahi `9200` yalnız `127.0.0.1` üzerinde yayınlanır.
- Tek node yalnız eğitim içindir. Üretimde hata alanlarına dağıtılmış master/data node rolleri tasarlanır.
- JVM heap ve shard sayısı gerçek ingest hacmiyle kapasite testine tabi tutulur.
- Persistent Queue ve DLQ dolulukları izlenir; DLQ kayıtları düzeltilip yeniden işlenir.
- ILM yanında ayrı depoda snapshot alınır ve restore düzenli test edilir.
- Parola, token, Authorization header ve kişisel veri loglanmaz; ingest öncesi maskelenir.
- Reverse proxy arkasında `client.ip` proxy IP'si olabilir. Yalnız güvenilir proxy CIDR'leriyle `real_ip_header` yapılandırılır; rastgele `X-Forwarded-For` başlığına güvenilmez.
- Log, metric ve trace korelasyonu için ortak `service.name`, `environment`, `trace.id` ve OpenTelemetry semantik alanları kullanılır.

## 11. Challenge

1. Kibana Lens ile toplam istek, durum kodu dağılımı, ilk beş URL ve `event.outcome: failure` panellerinden oluşan dashboard hazırlayın.
2. Nginx formatına `$request_time` ekleyin; Logstash ile `event.duration` üretirken eski `combined` kayıtlarını da destekleyin.
3. Elasticsearch'i iki dakika durdurup trafik üretin; yeniden açıldığında Persistent Queue kayıtlarının kaybolmadan indekslendiğini kanıtlayın:

```bash
cd ~/labs/LAB-LOG-01
sudo docker compose stop elasticsearch
curl -s http://localhost:8088/ >/dev/null
curl -s http://localhost:8088/test-500 >/dev/null
sudo docker compose start elasticsearch
sleep 30
curl -s http://localhost:9200/devops-nginx-*/_count | jq .count
```
