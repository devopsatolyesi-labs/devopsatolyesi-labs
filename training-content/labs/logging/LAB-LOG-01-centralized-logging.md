# LAB-LOG-01 — 2026 ELK Yığını: Nginx Loglarını Uçtan Uca Merkezileştirme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 75 dakika | `logging` | `Küme içi` |

[LAB-LOG-01.zip](/downloads/LAB-LOG-01.zip)


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

Dört benzersiz `filestream` input, lab/host access ve error loglarını okur. `fingerprint.length: 64`, küçük lab dosyalarının hemen izlenmesini sağlar. Yalnız düz metin `access.log` ve `access.log.1` seçilir; `.gz` dosyaları metinmiş gibi okunmaz.

### Adım 8 — Gerçek Nginx biçimine göre Grok filtresini inceleyin

```bash
sed -n '1,240p' ~/labs/LAB-LOG-01/logstash/pipeline/nginx.conf
```

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

## Doğal Doğrulama ve Beklenen Sonuç

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

## Doğal Doğrulama ve Beklenen Sonuç

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
