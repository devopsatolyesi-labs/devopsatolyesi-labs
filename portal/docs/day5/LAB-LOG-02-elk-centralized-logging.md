# LAB-LOG-02 — İleri ELK Gözlemlenebilirliği: Linux, Docker, Kubernetes, GeoMap ve Canvas

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 90 dakika | `logging, kubernetes` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-LOG-02.zip)](/downloads/LAB-LOG-02.zip) — paket README ve başlangıç kodlarını içerir; çözüm içermez.
> 
> **Terminalde çalışma ortamını hazırlayın:**
> ```bash
> mkdir -p ~/labs/LAB-LOG-02
> cd ~/labs/LAB-LOG-02
> ```


## 1. LAB-LOG-01 ile farkı

| Konu | LAB-LOG-01 — Temel | LAB-LOG-02 — İleri |
|---|---|---|
| Ana amaç | Nginx satırını Grok ile parse etmek | Çok kaynaklı gözlemlenebilirlik kurmak |
| Log kaynakları | Nginx access/error | Nginx, Linux syslog, Docker ve Kubernetes pod logları |
| Metrikler | Yok | Linux CPU/RAM/disk/ağ ve Docker CPU/RAM |
| Görselleştirme | Discover ve basit Lens dashboard | Birleşik dashboard, GeoMap ve Canvas workpad |
| Veri toplayıcı | Filebeat → Logstash | Vector + Filebeat Nginx modülü + Metricbeat |
| Zorluk | Başlangıç | İleri |

LAB-LOG-02, LAB-LOG-01'in tekrarı değildir. Burada log ve metrik ayrımı, birden fazla zaman alanı, ECS alanları, Kubernetes metadata'sı ve sunum katmanı birlikte ele alınır.

## 2. Mimari

```text
 /var/log/syslog ───────────────┐
 Docker stdout/stderr ──────────┼── Vector ───────> training-logs-*
 Kind Kubernetes pod logları ───┘                   log_type: linux|docker|kubernetes

 /var/log/nginx/access.log ─────── Filebeat nginx module
                                      └── ingest pipeline + GeoIP ──> devops-nginx-*

 /proc + /sys/fs/cgroup ───────── Metricbeat system module ────────> devops-metrics-system-*
 /var/run/docker.sock ─────────── Metricbeat docker module ────────> devops-metrics-docker-*

                                     Elasticsearch 8.17.8
                                              │
                                              v
                                     Kibana 8.17.8
                        Discover + Lens + Dashboard + Maps + Canvas
```

### Terimler

| Terim | Açıklama |
|---|---|
| **Log** | Bir olayın metinsel veya JSON kaydıdır. Örnek: pod hatası veya HTTP 500. |
| **Metric** | Zaman içinde ölçülen sayısal değerdir. Örnek: CPU kullanım yüzdesi. |
| **Vector** | Birden fazla log kaynağını okuyup dönüştüren ve Elasticsearch'e gönderen toplayıcıdır. |
| **Metricbeat** | Sistem ve servis metriklerini periyodik olarak ölçen Elastic Beat ajanıdır. |
| **Filebeat module** | Nginx gibi ürünler için input, ingest pipeline ve alan eşlemelerini birlikte sağlar. |
| **ECS** | Elastic Common Schema; `source.ip`, `event.dataset`, `container.name` gibi ortak alan sözleşmesidir. |
| **Data View** | Kibana'nın bir veya daha fazla indeks/data stream üzerindeki alanları görmesini sağlar. |
| **Lens** | Sürükle-bırak görselleştirme aracıdır. |
| **GeoIP** | IP adresini ülke, şehir ve `geo_point` konumuna zenginleştirme işlemidir. |
| **Canvas** | Operasyon ekranı veya sunum görünümü hazırlamak için kullanılan piksel tabanlı çalışma alanıdır. |

## 3. Ön kontroller

### 3.1 Temel paketleri elle kurun

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl jq docker.io docker-compose-v2 nginx rsyslog
sudo systemctl enable --now docker nginx rsyslog
sudo usermod -aG docker "$USER"
newgrp docker
```

`newgrp docker` yeni bir shell açar. Bundan sonraki komutları bu shell içinde çalıştırın.

### 3.2 Kind ve kubectl'i sabit sürümle kurun

```bash
curl -Lo /tmp/kind-linux-amd64 https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
curl -Lo /tmp/kind.sha256 https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64.sha256sum
cd /tmp
sha256sum --check kind.sha256
sudo install -m 0755 kind-linux-amd64 /usr/local/bin/kind

curl -Lo /tmp/kubectl https://dl.k8s.io/release/v1.31.9/bin/linux/amd64/kubectl
curl -Lo /tmp/kubectl.sha256 https://dl.k8s.io/release/v1.31.9/bin/linux/amd64/kubectl.sha256
printf '%s  %s\n' "$(cat /tmp/kubectl.sha256)" /tmp/kubectl | sha256sum --check
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
```

### 3.3 Üç düğümlü Kind kümesini oluşturun

Pod loglarının öğrenci hostundan okunabilmesi için her node'un `/var/log` dizinini hosta bağlayın:

```bash
sudo mkdir -p /var/log/devops-kind/{control-plane,worker,worker2}
sudo chmod -R 0755 /var/log/devops-kind
mkdir -p ~/labs/LAB-LOG-02
cd ~/labs/LAB-LOG-02
nano kind-config.yaml
```

`kind-config.yaml` içine şunu yapıştırın:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: devops-cluster
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/log/devops-kind/control-plane
        containerPath: /var/log
  - role: worker
    extraMounts:
      - hostPath: /var/log/devops-kind/worker
        containerPath: /var/log
  - role: worker
    extraMounts:
      - hostPath: /var/log/devops-kind/worker2
        containerPath: /var/log
```

Kümeyi oluşturun ve örnek log üreten pod'u başlatın:

```bash
kind create cluster --name devops-cluster \
  --image kindest/node:v1.31.9 \
  --config kind-config.yaml
kubectl get nodes
kubectl create namespace devops-demo
kubectl -n devops-demo create deployment log-generator --image=busybox:1.36 \
  -- sh -c 'while true; do echo "level=info service=log-generator message=heartbeat"; sleep 5; done'
kubectl -n devops-demo rollout status deployment/log-generator --timeout=120s
```

### 3.4 Kaynakları kontrol edin

```bash
free -h
df -h /
docker version
docker compose version
sudo test -r /var/log/syslog
sudo test -S /var/run/docker.sock
sudo test -r /var/log/nginx/access.log
kubectl get nodes
kubectl -n devops-demo get pods
```

Elasticsearch çekirdek gereksinimini elle uygulayın:

```bash
sudo sysctl -w vm.max_map_count=262144
printf 'vm.max_map_count=262144\n' | sudo tee /etc/sysctl.d/99-elk2.conf
```

Çalışma dizinlerini oluşturun:

```bash
mkdir -p ~/labs/LAB-LOG-02/{vector,metricbeat,filebeat}
cd ~/labs/LAB-LOG-02
```

## 4. Docker Compose dosyasını elle oluşturma

`nano compose.yaml` komutunu çalıştırın ve aşağıdaki içeriği yapıştırın:

```yaml
name: lab-log-02

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.17.8
    container_name: elk2-elasticsearch
    restart: unless-stopped
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      ES_JAVA_OPTS: -Xms1g -Xmx1g
    ulimits:
      memlock: {soft: -1, hard: -1}
    volumes:
      - es-data:/usr/share/elasticsearch/data
    ports:
      - "127.0.0.1:9200:9200"
    networks: [observability]
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:9200/_cluster/health"]
      interval: 10s
      timeout: 5s
      retries: 30

  kibana:
    image: docker.elastic.co/kibana/kibana:8.17.8
    container_name: elk2-kibana
    restart: unless-stopped
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
      TELEMETRY_ENABLED: "false"
    ports:
      - "5601:5601"
    depends_on:
      elasticsearch: {condition: service_healthy}
    networks: [observability]

  vector:
    image: timberio/vector:0.40.2-alpine
    container_name: elk2-vector
    restart: unless-stopped
    volumes:
      - ./vector/vector.yaml:/etc/vector/vector.yaml:ro
      - /var/log/syslog:/var/log/syslog:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/log/devops-kind:/var/log/kind:ro
    depends_on:
      elasticsearch: {condition: service_healthy}
    networks: [observability]

  metricbeat:
    image: docker.elastic.co/beats/metricbeat:8.17.8
    container_name: elk2-metricbeat
    restart: unless-stopped
    user: root
    command: ["metricbeat", "-e", "--strict.perms=false", "-E", "system.hostfs=/hostfs"]
    volumes:
      - ./metricbeat/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml:ro
      - /proc:/hostfs/proc:ro
      - /sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro
      - /:/hostfs:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      elasticsearch: {condition: service_healthy}
    networks: [observability]

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.17.8
    container_name: elk2-filebeat
    restart: unless-stopped
    user: root
    command: ["filebeat", "-e", "--strict.perms=false"]
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/log/nginx:/var/log/nginx:ro
      - filebeat-data:/usr/share/filebeat/data
    depends_on:
      elasticsearch: {condition: service_healthy}
    networks: [observability]

volumes:
  es-data:
  filebeat-data:

networks:
  observability:
```

Yapıyı doğrulayın:

```bash
docker compose config
```

## 5. Vector ile Linux, Docker ve Kubernetes logları

`nano vector/vector.yaml` ile dosyayı oluşturun:

```yaml
sources:
  docker_logs:
    type: docker_logs

  host_syslog:
    type: file
    include: [/var/log/syslog]
    read_from: beginning

  kubernetes_pod_logs:
    type: file
    include: ["/var/log/kind/*/pods/*/*/*.log"]
    read_from: beginning

transforms:
  tag_docker:
    type: remap
    inputs: [docker_logs]
    source: |
      .log_type = "docker"
      if match(string!(.container_name), r'^devops-cluster|^kind') {
        .log_type = "kubernetes"
      }
      .service = .container_name

  tag_kubernetes:
    type: remap
    inputs: [kubernetes_pod_logs]
    source: |
      .log_type = "kubernetes"
      parts = split(string!(.file), "/")
      pod_dir = string(parts[-3]) ?? "unknown_pod"
      pod_parts = split(pod_dir, "_")
      .k8s_namespace = string(pod_parts[0]) ?? "default"
      .k8s_pod = string(pod_parts[1]) ?? pod_dir
      .service = .k8s_pod

  tag_linux:
    type: remap
    inputs: [host_syslog]
    source: |
      .log_type = "linux"
      .service = "system"

sinks:
  elasticsearch:
    type: elasticsearch
    inputs: [tag_docker, tag_kubernetes, tag_linux]
    endpoints: ["http://elasticsearch:9200"]
    mode: bulk
    bulk:
      index: "training-logs-%Y.%m.%d"
```

Vector yapılandırmasını elle test edin:

```bash
docker compose run --rm vector validate /etc/vector/vector.yaml
```

## 6. Metricbeat ile Linux CPU/RAM ve Docker metrikleri

`nano metricbeat/metricbeat.yml` dosyasına şunları yapıştırın:

```yaml
metricbeat.modules:
  - module: system
    metricsets: [cpu, load, memory, network, process_summary, filesystem, fsstat, uptime]
    period: 10s
    processes: ['.*']

  - module: docker
    metricsets: [container, cpu, diskio, healthcheck, info, memory, network]
    hosts: ["unix:///var/run/docker.sock"]
    period: 10s

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~

output.elasticsearch:
  hosts: ["http://elasticsearch:9200"]
  index: "devops-metrics-%{[event.module]}-%{+yyyy.MM.dd}"

setup.template.enabled: true
setup.template.name: devops-metrics
setup.template.pattern: devops-metrics-*
setup.ilm.enabled: false
```

Elle doğrulayın:

```bash
docker compose run --rm metricbeat test config -e --strict.perms=false -E system.hostfs=/hostfs
```

## 7. Filebeat Nginx modülü ve GeoIP

`nano filebeat/filebeat.yml` dosyasını oluşturun:

```yaml
filebeat.modules:
  - module: nginx
    access:
      enabled: true
      var.paths: [/var/log/nginx/access.log, /var/log/nginx/access.log.1]
    error:
      enabled: true
      var.paths: [/var/log/nginx/error.log, /var/log/nginx/error.log.1]

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~

output.elasticsearch:
  hosts: ["http://elasticsearch:9200"]
  index: "devops-nginx-%{+yyyy.MM.dd}"

setup.template.enabled: true
setup.template.name: devops-nginx
setup.template.pattern: devops-nginx-*
setup.ilm.enabled: false
```

Filebeat yapılandırmasını test edin:

```bash
docker compose run --rm filebeat filebeat test config -e --strict.perms=false
```

Nginx ingest pipeline'ını elle yükleyin:

```bash
docker compose run --rm filebeat \
  filebeat setup --pipelines --modules nginx -e --strict.perms=false
```

Bu pipeline, Nginx satırını ECS alanlarına ayırır ve genel IP adresleri için `source.geo.location` alanını `geo_point` olarak üretir. Özel IP adresleri haritada gösterilmez.

## 8. Servisleri elle başlatma

```bash
docker compose pull
docker compose up -d
docker compose ps
docker stats --no-stream
```

### 8.1 Nginx ve GeoIP için deterministik eğitim verisi üretin

Önce gerçek Nginx trafiği üretin:

```bash
curl -s http://127.0.0.1/ >/dev/null
curl -s http://127.0.0.1/olmayan-sayfa >/dev/null
```

Yerel istekler `127.0.0.1` kaynağına sahip olduğu için GeoIP konumu üretmez. GeoMap laboratuvarının her öğrenci sunucusunda aynı sonucu vermesi için aşağıdaki üç satırı eğitim verisi olarak elle ekleyin. Bunların gerçek ziyaretçi kaydı değil, dokümante edilmiş sentetik veri olduğunu unutmayın:

```bash
stamp=$(LC_ALL=C date '+%d/%b/%Y:%H:%M:%S %z')
printf '8.8.8.8 - - [%s] "GET /geo/google HTTP/1.1" 200 42 "-" "LAB-LOG-02-GeoProbe/1.0"\n' "$stamp" | sudo tee -a /var/log/nginx/access.log
printf '1.1.1.1 - - [%s] "GET /geo/cloudflare HTTP/1.1" 200 42 "-" "LAB-LOG-02-GeoProbe/1.0"\n' "$stamp" | sudo tee -a /var/log/nginx/access.log
printf '208.67.222.222 - - [%s] "GET /geo/opendns HTTP/1.1" 500 42 "-" "LAB-LOG-02-GeoProbe/1.0"\n' "$stamp" | sudo tee -a /var/log/nginx/access.log
sleep 15
```

Kind pod logunun hosta ulaştığını ayrıca doğrulayın:

```bash
sudo find /var/log/devops-kind -path '*/pods/*/*/*.log' -type f | head
kubectl -n devops-demo logs deployment/log-generator --tail=3
```

İndeksleri doğrulayın:

```bash
curl -s 'http://localhost:9200/_cat/indices?v&s=index'
curl -s 'http://localhost:9200/training-logs-*/_count' | jq .
curl -s 'http://localhost:9200/devops-metrics-*/_count' | jq .
curl -s 'http://localhost:9200/devops-nginx-*/_count' | jq .
```

Kaynak dağılımını kontrol edin:

```bash
curl -s -H 'Content-Type: application/json' \
  'http://localhost:9200/training-logs-*/_search' \
  -d '{"size":0,"aggs":{"sources":{"terms":{"field":"log_type.keyword"}}}}' \
  | jq '.aggregations.sources.buckets'
```

GeoIP belge sayısı:

```bash
curl -s -H 'Content-Type: application/json' \
  'http://localhost:9200/devops-nginx-*/_search' \
  -d '{"size":0,"query":{"exists":{"field":"source.geo.location"}}}' \
  | jq '.hits.total.value'
```

## 9. Data View'ları Kibana arayüzünde elle oluşturma

Kibana'yı `http://SUNUCU_IP:5601` adresinden açın. **Stack Management → Data Views → Create data view** yolunu izleyin.

| Ad | Index pattern | Zaman alanı |
|---|---|---|
| Linux, Docker ve Kubernetes Logları | `training-logs-*` | `timestamp` |
| Nginx GeoIP Logları | `devops-nginx-*` | `@timestamp` |
| Linux ve Docker Metrikleri | `devops-metrics-*` | `@timestamp` |

Discover'da aşağıdaki KQL sorgularını deneyin:

```text
log_type: "kubernetes"
```

```text
log_type: "docker" and level: "error"
```

```text
event.dataset: "system.cpu"
```

## 10. İleri dashboard'u elle oluşturma

**Analytics → Dashboard → Create dashboard** yolunu izleyin ve adı `ELK2 İleri Gözlemlenebilirlik Merkezi` olsun.

### Panel 1 — Linux CPU

1. **Create visualization → Lens** seçin.
2. Data View: **Linux ve Docker Metrikleri**.
3. KQL: `event.dataset: "system.cpu"`.
4. Y ekseni: Average of `system.cpu.total.norm.pct`.
5. Format: Percent; grafik tipi: Line.

### Panel 2 — Linux RAM

1. KQL: `event.dataset: "system.memory"`.
2. Y ekseni: Average of `system.memory.actual.used.pct`.
3. Format: Percent; grafik tipi: Area.

### Panel 3 — Docker konteyner CPU/RAM

1. KQL: `event.module: "docker"`.
2. Breakdown: `container.name`.
3. Metrikler: `docker.cpu.total.pct` ve `docker.memory.usage.pct`.

### Panel 4 — Linux/Docker/Kubernetes log dağılımı

1. Data View: **Linux, Docker ve Kubernetes Logları**.
2. Grafik tipi: Bar veya Donut.
3. Slice/Breakdown: Top values of `log_type.keyword`.
4. Metric: Count of records.

### Panel 5 — Hata tablosu

1. KQL: `level: "error" or message: *error*`.
2. Sütunlar: `timestamp`, `log_type`, `service`, `k8s_namespace`, `k8s_pod`, `message`.

Dashboard zaman aralığını **Last 24 hours**, otomatik yenilemeyi **30 seconds** yapın ve kaydedin.

## 11. Nginx GeoMap'i elle oluşturma

1. **Analytics → Maps → Create map**.
2. **Add layer → Documents** veya **Clusters and grids**.
3. Data View: **Nginx GeoIP Logları**.
4. Geospatial field: `source.geo.location`.
5. Tooltip alanları: `source.ip`, `source.geo.country_name`, `url.original`, `http.response.status_code`.
6. Küme boyutunu document count'a göre dinamik yapın.
7. Haritayı `Nginx İstemci GeoMap` adıyla kaydedin.
8. **Add to dashboard** ile ileri dashboard'a ekleyin.

Harita boşsa önce `source.geo.location` sorgusunun sıfırdan büyük olduğunu doğrulayın. `127.0.0.1`, `10.0.0.0/8`, `172.16.0.0/12` ve `192.168.0.0/16` adreslerinin konum üretmemesi normaldir.

## 12. Canvas workpad'i elle oluşturma

1. **Analytics → Canvas → Create workpad**.
2. Ad: `DevOps Operasyon Merkezi`; çözünürlük: `1280x720`.
3. Koyu arka plan ve başlık ekleyin.
4. **Add element → Metric** ile şu kartları oluşturun:
   - Toplam Nginx isteği
   - HTTP 5xx sayısı
   - Ortalama Linux CPU yüzdesi
   - Ortalama Linux RAM yüzdesi
   - Kubernetes log sayısı
   - Docker error log sayısı
5. **Add from library** ile `Nginx İstemci GeoMap` nesnesini ekleyin.
6. Zaman filtresi ekleyip workpad'i kaydedin.

Canvas, dashboard'un yerine geçmez. Dashboard etkileşimli analiz içindir; Canvas NOC ekranı, TV görünümü veya yönetsel sunum için kullanılır.

## 13. Canlı ELK2 kabul kanıtı

GCP `training-runtime-01` üzerinde doğrulanan gerçek sonuçlar:

- Nginx GeoIP belgeleri: **601+**
- Kubernetes logları: **204.000+**
- Linux logları: **29.000+**
- Docker logları: **7.900+**
- `devops-metrics-system-*`, `devops-metrics-docker-*` ve `devops-nginx-*` data stream'leri aktif
- `ELK2 İleri Gözlemlenebilirlik Merkezi`, `Nginx İstemci GeoMap` ve `DevOps Operasyon Merkezi` Canvas nesneleri Kibana 8.17.8 tarafından başarıyla kabul edildi

Sayılar zamanla artar; kabul kriteri alanların ve veri akışlarının bulunmasıdır.

## 14. Sorun giderme

```bash
docker compose logs --tail=100 vector
docker compose logs --tail=100 metricbeat
docker compose logs --tail=100 filebeat
curl -s http://localhost:9200/_cluster/health | jq .
```

- `permission denied /var/log/syslog`: Vector konteynerinin root olarak çalıştığını ve bind mount'u kontrol edin.
- Docker metriği yok: `/var/run/docker.sock` mount'unu kontrol edin.
- Kubernetes logu yok: Kind/Kubernetes node'unun gerçek pod log dizinini bulun; dağıtıma göre yol değişebilir.
- GeoMap boş: Nginx ingest pipeline'ının yüklendiğini ve `source.geo.location` mapping tipinin `geo_point` olduğunu doğrulayın.
- CPU/RAM paneli boş: Data View zaman alanının `@timestamp`, zaman aralığının Last 15 minutes olduğunu kontrol edin.

## 15. Manuel temizlik

Yalnız bu labın Compose kaynaklarını kaldırın:

```bash
cd ~/labs/LAB-LOG-02
docker compose down
```

Lab verilerini de silmek istiyorsanız ve doğru dizinde olduğunuzu doğruladıysanız:

```bash
pwd
docker compose down -v
```

## 16. Production notları

- Eğitimde kapalı olan Elastic security üretimde TLS, RBAC ve secret yönetimiyle açılır.
- Docker socket root yetkisine eşdeğer kabul edilir; salt okunur mount tek başına tam güvenlik sınırı değildir.
- Kubernetes üretiminde node dosya yolu yerine Elastic Agent/Filebeat DaemonSet ve sınırlı ServiceAccount kullanılır.
- Log ve metrikler için ayrı ILM/data tier politikaları uygulanır.
- `authorization`, token, parola, kişisel veri ve kart bilgisi ingest öncesinde maskelenir.
- GeoIP yaklaşık konumdur; kesin kullanıcı konumu olarak değerlendirilmez.
- Dashboard sorguları yüksek cardinality alanlarında sınırlandırılır.
