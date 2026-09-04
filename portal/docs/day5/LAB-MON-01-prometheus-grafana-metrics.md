# LAB-MON-01 — Prometheus Architecture, Scrape Targets & PromQL Basics

> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/LAB-MON-01.zip) — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.


İndirdikten sonra terminalde: `unzip LAB-MON-01.zip && cd LAB-MON-01`

## ZIP İndirmeden Dosyaları Oluşturma

Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.

```bash
mkdir -p ~/labs/LAB-MON-01
cd ~/labs/LAB-MON-01
```

### `starter/prometheus.yml`

```bash
mkdir -p "$(dirname -- starter/prometheus.yml)"
cat > starter/prometheus.yml <<'LAB_FILE_EOF_1'
# TODO: Configure Prometheus scrape job
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
LAB_FILE_EOF_1
```

### `scripts/cleanup.sh`

```bash
mkdir -p "$(dirname -- scripts/cleanup.sh)"
cat > scripts/cleanup.sh <<'LAB_FILE_EOF_2'
#!/usr/bin/env bash
echo "Cleanup completed for LAB-MON-01."
LAB_FILE_EOF_2
chmod +x scripts/cleanup.sh
```

### `scripts/reset.sh`

```bash
mkdir -p "$(dirname -- scripts/reset.sh)"
cat > scripts/reset.sh <<'LAB_FILE_EOF_3'
#!/usr/bin/env bash
set -euo pipefail
lab_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
echo "Resetting workspace for LAB-MON-01..."
bash "$lab_dir/scripts/cleanup.sh"
cp -r "$lab_dir/starter"/. .
echo "Workspace reset to starter state for LAB-MON-01."
LAB_FILE_EOF_3
chmod +x scripts/reset.sh
```

### `scripts/validate.sh`

```bash
mkdir -p "$(dirname -- scripts/validate.sh)"
cat > scripts/validate.sh <<'LAB_FILE_EOF_4'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Validating LAB-MON-01: Prometheus configuration..."
docker run --rm -v "$(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml" prom/prometheus:v3.13.2 check config /etc/prometheus/prometheus.yml
echo "[PASS] Prometheus configuration syntax verified."
LAB_FILE_EOF_4
chmod +x scripts/validate.sh
```

Başlangıç dosyalarını çalışma dizinine alın:

```bash
cp -a starter/. .
```


## 1. Lab Senaryosu
Mikroservis mimarilerinde sistemlerin sağlıklı çalıştığını yalnızca sunucunun ayakta olmasına bakarak anlamak mümkün değildir. Uygulamaların saniye başına işlediği istek sayısı (RPS), HTTP 5xx hata oranları ve 95. yüzdelik (p95) yanıt gecikmeleri gibi "Golden Signals" metriklerinin sürekli toplanması ve görselleştirilmesi gerekir. Prometheus, çekme (pull) mimarisiyle çalışan endüstri standardı zaman serisi veritabanıdır. Bu çalışmada Python FastAPI mikroservisine metrik enstrümantasyonu eklenir; Prometheus 3.x LTS ile metrik kazıma hedefleri tanımlanır ve Grafana 13 panellerinde PromQL sorguları ile görselleştirilir.

## 2. Amaç
Prometheus 3.x LTS çekme (pull) mimarisini kurmak, `prometheus.yml` ile uygulama ve sistem metrik kazıma hedeflerini tanımlamak, `rate()` ve `sum()` PromQL sorguları ile HTTP istek oranlarını analiz etmek ve Grafana 13 otomatik veri kaynağı (data source provisioning) yapılandırmasını doğrulamak.

## 3. Mimari / Akış
```text
  [ Prometheus 3.13.2 LTS Sunucusu (Port: 9090) ]
        |
        |--- (5 saniyede bir /metrics çekilir) ---> [ Uygulama: order-api (Port: 8000) ]
        |--- (5 saniyede bir /metrics çekilir) ---> [ Node Exporter (Port: 9100) ]
        |
        v
  [ Grafana 13.1.5 Paneli (Port: 3000) ] <--- (PromQL Sorgulaması)
```

```mermaid
flowchart LR
    subgraph TARGETS [Metrik Kaynakları (Targets)]
        APP["order-api (:8000/metrics)\nHTTP İstek & Gecikme"]
        NODE["Node Exporter (:9100/metrics)\nCPU, RAM, Disk, Ağ"]
        PROM_SELF["Prometheus (:9090/metrics)\nTSDB Durumu"]
    end

    subgraph PROM [Prometheus 3.13.2 LTS Engine]
        SCRAPER[Periyodik Kazıma / Pull Engine]
        TSDB[(Zaman Serisi Veritabanı - TSDB)]
        PROMQL[PromQL Sorgu Motoru]
        SCRAPER --> TSDB
        TSDB --> PROMQL
    end

    subgraph VIZ [Görselleştirme]
        GRAF[Grafana 13.1.5 Paneli :3000]
        USER((Operatör / SRE))
        PROMQL -->|PromQL HTTP API| GRAF
        GRAF --> USER
    end

    APP -->|Pull 5s| SCRAPER
    NODE -->|Pull 5s| SCRAPER
    PROM_SELF -->|Pull 5s| SCRAPER

    classDef target fill:#1e1b4b,stroke:#818cf8,color:#fff;
    classDef prom fill:#431407,stroke:#f97316,color:#fff;
    classDef viz fill:#422006,stroke:#f59e0b,color:#fff;

    class TARGETS target;
    class PROM prom;
    class VIZ viz;
```

> [!NOTE]
> **Çekme (Pull) vs İtme (Push) Modeli:** Prometheus, metrikleri uygulamaların kendisine göndermesini (push) beklemez; konfigürasyonundaki hedeflerin `/metrics` uç noktalarını periyodik olarak (burada her 5 saniyede bir) yoklayarak (pull) zaman serisi veritabanına kaydeder.


## 4. Ön Koşullar
- Docker Engine ve Docker Compose v2 çalışır durumda olmalıdır
- Host üzerinde 9090, 3000, 9100 ve 8000 portları boş olmalıdır
- `curl` ve `jq` araçları kurulu olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-DOC-05`

Aşağıdaki komutlarla çalışma ortamını hazırlayın:
```bash
docker compose version
mkdir -p ~/labs/LAB-MON-01/app ~/labs/LAB-MON-01/prometheus ~/labs/LAB-MON-01/grafana/provisioning/datasources
cd ~/labs/LAB-MON-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Metrik Üreten Demo Uygulama Kodunu Hazırlama
FastAPI mikroservisi ve Prometheus Instrumentator kütüphanesini içeren dosyaları oluşturun:
```bash
cat <<'EOF' > app/main.py
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
import random
import time
import uvicorn

app = FastAPI(title="Metrics Instrumentated API", version="3.0.0")

# Prometheus metrik toplayıcısını bağla
Instrumentator().instrument(app).expose(app)

@app.get("/")
def home():
    time.sleep(random.uniform(0.01, 0.05))
    return {"message": "Observability API is Active on Prometheus 3.x"}

@app.get("/heavy")
def heavy():
    time.sleep(0.2)
    return {"status": "processed heavy calculation"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

cat <<'EOF' > app/requirements.txt
fastapi==0.110.0
uvicorn==0.28.0
prometheus-fastapi-instrumentator==7.0.0
EOF

cat <<'EOF' > app/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
EXPOSE 8000
CMD ["python", "main.py"]
EOF
```

### Adım 2 — Prometheus Scrape Yapılandırmasını Tanımlama
Uygulama ve Node Exporter hedeflerini 5 saniyelik periyotla kazıyacak `prometheus.yml` dosyasını oluşturun:
```yaml
cat <<'EOF' > prometheus/prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'order-api'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['order-api:8000']
EOF
```

### Adım 3 — Otomatik Grafana Veri Kaynağı Yapılandırması
Grafana'nın Prometheus'a doğrudan bağlanması için provisioning tanımını oluşturun:
```yaml
cat <<'EOF' > grafana/provisioning/datasources/datasource.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF
```

### Adım 4 — Docker Compose ile Gözlemlenebilirlik Kümesini Başlatma
Prometheus, Grafana ve uygulamayı içeren `compose.yaml` dosyasını oluşturup başlatın:
```yaml
cat <<'EOF' > compose.yaml
services:
  order-api:
    build:
      context: ./app
    container_name: order-api
    ports:
      - "8000:8000"

  node-exporter:
    image: prom/node-exporter:v1.8.2
    container_name: node-exporter
    ports:
      - "9100:9100"

  prometheus:
    image: prom/prometheus:v3.13.2
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    depends_on:
      - order-api
      - node-exporter

  grafana:
    image: grafana/grafana:13.1.5
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    depends_on:
      - prometheus
EOF
```

```bash
docker compose up -d --build
sleep 5
```

### Adım 5 — Sentetik Trafik Üretme ve PromQL ile Metrik Sorgulama
Uygulamaya ardışık istekler göndererek metrik üretimini tetikleyin ve PromQL ile sorgulayın:
```bash
# Sentetik HTTP trafigi uret
for i in {1..20}; do
  curl -s http://localhost:8000/ > /dev/null
  curl -s http://localhost:8000/heavy > /dev/null
done

# PromQL ile RPS sorgula
curl -s "http://localhost:9090/api/v1/query?query=rate(http_requests_total%5B1m%5D)" | jq .
```

## 6. Beklenen Sonuç
Adım 5'teki PromQL JSON sorgu çıktısı:
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "handler": "/",
          "job": "order-api",
          "status": "2xx"
        },
        "value": [...]
      }
    ]
  }
}
```

## 7. Doğrulama
Prometheus üzerinde 3 hedefin (`prometheus`, `node-exporter`, `order-api`) `UP` durumunda olduğunu doğrulayın:
```bash
TARGETS_UP=$(curl -s http://localhost:9090/api/v1/targets | jq '[.data.activeTargets[] | select(.health=="up")] | length')

if [ "$TARGETS_UP" -ge 3 ]; then
  echo "VALIDATION SUCCESS: Prometheus 3.13 LTS is scraping 3/3 targets in UP state."
else
  echo "VALIDATION FAILED: Active UP targets: $TARGETS_UP" && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
Prometheus arayüzünde (`http://localhost:9090/targets`) `order-api` hedefi `DOWN` görünür ve `connection refused` hatası verir.

### Kanıt
Target endpoint adresinde Docker iç ağı yerine `localhost` yazıldığı görülür.

### Kontrol Komutu
```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job=="order-api")'
```

### Muhtemel Neden
`prometheus.yml` dosyasında hedef `localhost:8000` olarak girilmiştir; Docker köprü ağında konteynerler kendi servis isimleriyle (`order-api:8000`) erişilmelidir.

### Çözüm
`prometheus/prometheus.yml` dosyasında hedefi `order-api:8000` olarak güncelleyin ve Prometheus servisini yeniden başlatın:
```bash
docker restart prometheus
```

### Tekrar Doğrulama
```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job=="order-api") | .health'
# "up" yanıtı dönmelidir.
```

## 9. Temizlik / Sıfırlama
Konteynerleri, ağları ve oluşturulan dizini temizleyin:
```bash
docker compose down -v
rm -rf ~/labs/LAB-MON-01
```

## 10. Production Notu
Üretim ortamlarında TSDB (Time Series Database) disk doluluğunu engellemek için veri saklama süresi (`--storage.tsdb.retention.time=15d` veya boyut sınırı `--storage.tsdb.retention.size=50GB`) kesinlikle belirlenmelidir. Ayrıca karmaşık PromQL sorgularının her dashboard yenilemesinde veritabanını yormaması için Recording Rules tanımlanarak önceden hesaplanmış zaman serileri oluşturulmalıdır.

## 11. Challenge
Grafana arayüzünde (`http://localhost:3000`) 95. yüzdelik yanıt süresini hesaplayan şu PromQL sorgusuyla yeni bir panel oluşturun: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))`
