# Project 06: Production Centralized Logging with ELK Stack (Elasticsearch 8.17.8, Logstash, Kibana, Filebeat)

## Overview & Architecture

This project implements an enterprise-grade **Centralized Logging Architecture** using the official Elastic 8.x stack (Elasticsearch 8.17.8, Logstash 8.17.8, Kibana 8.17.8, and Filebeat 8.17.8). It transforms scattered application logs, Docker container outputs, and Nginx web server access logs into an indexed, searchable, and structured data lake with automated lifecycle management (ILM) and visual Kibana analytics.

```text
 ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
 │                                   LOG PRODUCERS & COLLECTORS                                │
 └─────────────────────────────────────────────────────────────────────────────────────────────┘
   [ Node.js Order API ] --------> (Winston stdout / TCP:5000) ───┐
   [ Python Payment Worker ] ----> (Structured JSON / TCP:5000) ──┼──> [ Logstash Pipeline ]
   [ Nginx Access Logs ] --------> (Filebeat Shipper:5044) ────────┤      (Parse, Grok, PII-Sanitize,
   [ External REST Clients ] ----> (HTTP Ingest:8085) ─────────────┘       GeoIP, Normalize)
                                                                                  │
                                                                                  ▼
 ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
 │                                    ELASTICSEARCH & KIBANA                                   │
 └─────────────────────────────────────────────────────────────────────────────────────────────┘
   [ Elasticsearch 8.17.8 (Port 9200) ] <─────────────────────────────────────────┘
     ├── Index Pattern: logs-YYYY.MM.DD
     ├── Index Lifecycle Policy (ILM): logs-policy (Hot -> Warm -> Cold -> Delete)
     └── Index Template: logs-template
            │
            ▼
   [ Kibana UI 8.17.8 (Port 5601) ]
     ├── Data View: logs-* (@timestamp)
     ├── Discover Search & KQL Queries
     └── Dashboards: Real-time Traffic, Error Rates & Latency Heatmaps
```

---

## Key Features

1. **Latest Stable Elastic 8.17.8 Images**: No legacy or deprecated v7/v6 syntax.
2. **Multi-Channel Log Ingest**:
   - **Beats (Filebeat)**: Port `5044`
   - **TCP Stream (JSON Lines)**: Port `5000`
   - **HTTP REST Endpoint**: Port `8085` (`8080` container port)
   - **Direct Elasticsearch API**: Port `9200`
3. **Advanced Logstash Processing**:
   - JSON autodetection and flattening.
   - Nginx Combined Access Log Grok patterns (`client_ip`, `request_path`, `status`, `response_bytes`).
   - PII & Secret Sanitization (strips `password`, `token`, `credit_card`, `ssn`, `cvv`, `api_key`).
   - Incident Alert tagging (`incident_alert`) for `level:ERROR` and HTTP 5xx responses.
4. **Index Lifecycle Management (ILM)**:
   - **Hot (0-7d)**: Fast search & indexing, 10GB rollover.
   - **Warm (7-30d)**: Shrunk to 1 shard, force-merged to 1 segment.
   - **Cold (30-90d)**: Low priority storage.
   - **Delete (90d+)**: Automatic cleanup.
5. **Cockpit & Student Environment Compatibility**:
   - Memory tuned: `ES_JAVA_OPTS=-Xms1g -Xmx1g`, `LS_JAVA_OPTS=-Xms512m -Xmx512m` (runs smoothly inside 8-16 GB VM alongside student workloads without triggering Linux OOM Killer).
   - Port conflicts avoided: Standard non-colliding host ports.

---

## Quick Start & Step-by-Step Execution

### 1. Preflight System Setup (Linux Kernel Setting)
Elasticsearch requires `vm.max_map_count` to be at least `262144`:
```bash
sudo sysctl -w vm.max_map_count=262144
```

### 2. Start the ELK Stack
```bash
cd ~/devops-workspace/projects/project-06-elk-stack
docker compose up -d --build
```

### 3. Initialize Elasticsearch ILM & Templates
```bash
bash scripts/init-elasticsearch.sh
```

### 4. Initialize Kibana Data Views
```bash
bash scripts/init-kibana.sh
```

### 5. Generate Multi-Channel Test Telemetry
```bash
bash scripts/generate-logs.sh
```

### 6. Run Automated End-to-End Validation
```bash
bash scripts/validate.sh
```

---

## Verifying Logs via REST API & CLI

### List Indices:
```bash
curl -s http://localhost:9200/_cat/indices?v
```

### Search Recent Logs:
```bash
curl -s "http://localhost:9200/logs-*/_search?size=3&pretty"
```

### Search Only Errors:
```bash
curl -s "http://localhost:9200/logs-*/_search?q=level:ERROR&pretty"
```

### Check ILM Policy Status:
```bash
curl -s http://localhost:9200/_ilm/policy/logs-policy?pretty
```

---

## Accessing Kibana Dashboard

1. Open your browser: `http://localhost:5601` (or via your Cockpit / Student reverse proxy).
2. Go to **Analytics > Discover**.
3. Select the Data View `logs-*`.
4. Run sample KQL queries:
   - `level : "ERROR"`
   - `service : "order-api" and status >= 400`
   - `trace_id : *`

---

## Teardown & Reset

```bash
# To stop and remove containers & data:
bash scripts/cleanup.sh

# To reset fresh and re-seed all test logs:
bash scripts/reset.sh
```
