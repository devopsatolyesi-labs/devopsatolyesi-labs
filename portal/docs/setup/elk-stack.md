# ELK Stack Merkezi Loglama Kurulumu

Bu rehber; mikroservis, container ve sistem loglarını merkezi bir noktada toplamak, filtrelemek ve aramak için **Elasticsearch, Logstash ve Kibana (ELK)** mimarisinin kurulumunu açıklar.

---

## 1. Docker Compose ile ELK Stack Kurulumu

### Adım 1: Sistem Bellek Sınırını (vm.max_map_count) Ayarlayın

Elasticsearch için kernel bellek ayarı:

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Adım 2: Logstash Yapılandırma Dosyası

```bash
mkdir -p ~/elk-setup/logstash/pipeline
cd ~/elk-setup

cat <<'EOF' > logstash/pipeline/logstash.conf
input {
  tcp {
    port => 5000
    codec => json
  }
  beats {
    port => 5044
  }
}

filter {
  mutate {
    add_tag => [ "devops-lab-log" ]
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "devops-logs-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
EOF
```

### Adım 3: docker-compose.yaml

```bash
cat <<'EOF' > docker-compose.yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.12.0
    container_name: logstash
    volumes:
      - ./logstash/pipeline/logstash.conf:/usr/share/logstash/pipeline/logstash.conf:ro
    ports:
      - "5000:5000"
      - "5044:5044"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  es_data:
EOF

docker compose up -d
```

---

## 2. Doğrulama ve Test Logu Gönderme

```bash
# Elasticsearch sağlık durumu
curl -s http://localhost:9200/_cat/health?v

# Logstash TCP portuna test JSON logu gönderin
echo '{"level":"info","message":"DevOps Atolyesi ELK Stack Testi","service":"auth-api"}' | nc -q0 localhost 5000

# Kibana arayüzüne http://<IP>:5601 üzerinden erişin.
```
