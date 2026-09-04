# LAB-MON-02 — Prometheus Alertmanager: High Latency & Pod Crash Alerts

## Metadata
- **Seviye:** PRACTITIONER
- **Önerilen Gün:** Gün 5
- **Tahmini Süre:** 45 dk
- **Gerekli Profil:** `monitoring`
- **Host Portları:** `9090:9090` (Prometheus), `9093:9093` (Alertmanager)
- **Çalışma Dizini:** `~/labs/LAB-MON-02`

---

## 1. Lab Senaryosu
Metrikleri grafik panellerinde izlemek pasif bir operasyon yöntemidir; kesinti veya performans düşüşü yaşandığında mühendislerin anında haberdar edilmesi gerekir. Ancak anlık dalgalanmalarda yüzlerce gereksiz bildirim göndermek "Alert Fatigue" (alarm yorgunluğu) oluşturur. Prometheus kuralları (`for:` süresi) ile alarmları doğrular ve bildirimi Alertmanager bileşenine iletir. Alertmanager alarmları gruplar, tekilleştirir (deduplication) ve ilgili kanallara yönlendirir. Bu çalışmada kapalı bir servis üzerinden kasıtlı kesinti simülasyonu yapılır; `ServiceDown` alarmının `Pending` aşamasından `Firing` durumuna geçişi ve Alertmanager API v2 üzerindeki alarm kaydı doğrulanır.

## 2. Amaç
Prometheus üzerinde `alert.rules.yml` dosyasıyla alarm eşikleri tanımlamak, yalancı alarmları önlemek için `for: 30s` bekleme süresi kurgulamak, Alertmanager v0.33 entegrasyonu ile alarm durumunu (`Pending` -> `Firing`) ve API v2 çıktısını doğrulamak.

## 3. Mimari / Akış
```text
  [ Prometheus 3.13.2 LTS Motoru ]
           |
           +---> 5 saniyede bir 'alert.rules.yml' değerlendirilir
           |     - ServiceDown (up == 0) kuralı
           |
           v (Alarm Yükü API v2 ile iletilir)
  [ Alertmanager v0.33.0 (Port: 9093) ]
           |
           +---> Tekilleştirme & Gruplama
           +---> Webhook Alıcısına Yönlendirme
```

## 4. Ön Koşullar
- Docker Engine ve Docker Compose v2 çalışır durumda olmalıdır
- Host üzerinde 9090 ve 9093 portları boş olmalıdır
- `curl` ve `jq` araçları kurulu olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-MON-01`

Aşağıdaki komutlarla çalışma ortamını hazırlayın:
```bash
mkdir -p ~/labs/LAB-MON-02/prometheus ~/labs/LAB-MON-02/alertmanager
cd ~/labs/LAB-MON-02
```

## 5. Adım Adım Uygulama

### Adım 1 — Alarm Kurallarını ve Alertmanager Yapılandırmasını Tanımlama
Alarm eşiğini ve bildirim alıcılarını belirten dosyaları hazırlayın:
```yaml
cat <<'EOF' > prometheus/alert.rules.yml
groups:
  - name: devops_service_alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Servis erisilemez durumda: {{ $labels.instance }}"
          description: "Izlenen servis 30 saniyeden uzun suredir yanit vermiyor."
EOF

cat <<'EOF' > alertmanager/alertmanager.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'job']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'webhook-receiver'

receivers:
  - name: 'webhook-receiver'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true
EOF

cat <<'EOF' > prometheus/prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

rule_files:
  - "/etc/prometheus/alert.rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'test-service'
    static_configs:
      - targets: ['localhost:9999'] # Kasitli kapali port (Alarm tetikleyici)
EOF
```

### Adım 2 — `compose.yaml` ile Ortamı Başlatma
Prometheus ve Alertmanager servislerini içeren Compose dosyasını oluşturup ayağa kaldırın:
```yaml
cat <<'EOF' > compose.yaml
services:
  prometheus:
    image: prom/prometheus:v3.13.2
    container_name: prometheus-alert-test
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alert.rules.yml:/etc/prometheus/alert.rules.yml:ro
    depends_on:
      - alertmanager

  alertmanager:
    image: prom/alertmanager:v0.33.0
    container_name: alertmanager-test
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
EOF
```

```bash
docker compose up -d
sleep 10
```

### Adım 3 — Alarm Durum Geçişini İzleme
İlk 30 saniye içinde alarmın `pending` durumunda olduğunu sorgulayın:
```bash
curl -s http://localhost:9090/api/v1/alerts | jq .
```

30 saniye geçtikten sonra alarmın `firing` durumuna ulaştığını ve Alertmanager'a aktarıldığını doğrulayın:
```bash
sleep 30

# Prometheus uzerinde alarm durumu
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[0].state'

# Alertmanager API v2 uzerinde aktif alarmlar
curl -s http://localhost:9093/api/v2/alerts | jq '.[0].labels.alertname'
```

## 6. Beklenen Sonuç
İlk sorgudaki `pending` durumu:
```json
{
  "status": "success",
  "data": {
    "alerts": [
      {
        "labels": {
          "alertname": "ServiceDown",
          "severity": "critical"
        },
        "state": "pending"
      }
    ]
  }
}
```

30 saniye sonrasındaki durum çıktıları:
```text
"firing"
```
```text
"ServiceDown"
```

## 7. Doğrulama
`ServiceDown` alarmının Prometheus üzerinde `firing` durumunda olduğunu doğrulayın:
```bash
ALERT_STATE=$(curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.alertname=="ServiceDown") | .state')

if [ "$ALERT_STATE" = "firing" ]; then
  echo "VALIDATION SUCCESS: ServiceDown alert successfully transitioned to FIRING on Prometheus 3.x & Alertmanager v0.33."
else
  echo "VALIDATION FAILED: Expected state 'firing', got '$ALERT_STATE'." && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
Prometheus başlatılırken kural yükleme hatası verir veya `/api/v1/rules` boş döner.

### Kanıt
`docker logs prometheus-alert-test` çıktısında `yaml: line X: did not find expected key` hatası görülür.

### Kontrol Komutu
```bash
curl -s http://localhost:9090/api/v1/rules | jq .
```

### Muhtemel Neden
`prometheus/alert.rules.yml` dosyasında girinti (indentation) veya sözdizimi hatası bulunmaktadır.

### Çözüm
Kural dosyasındaki YAML yapısını düzeltin ve servisi yeniden başlatın:
```bash
docker compose restart prometheus
```

### Tekrar Doğrulama
```bash
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[0].name'
# "devops_service_alerts" dönmelidir.
```

## 9. Temizlik / Sıfırlama
Konteynerleri kaldırın ve çalışma dizinini temizleyin:
```bash
docker compose down -v
rm -rf ~/labs/LAB-MON-02
```

## 10. Production Notu
Üretim ortamlarında her alarm kuralına mutlaka bir runbook linki (`annotations.runbook_url`) eklenmelidir; nöbetçi mühendisin arıza anında ilk yapacağı teşhis adımları alarmın içinde bulunmalıdır. Ayrıca kök neden arızalarında (örneğin veri merkezi veya ana şalter kesintisi) yüzlerce alt alarmın patlamasını engellemek için Alertmanager üzerinde `inhibit_rules` (baskılama kuralları) yapılandırılmalıdır.

## 11. Challenge
Alertmanager API v2 endpoint'ine (`POST /api/v2/silences`) cURL ile istek göndererek `ServiceDown` alarmını 1 saat boyunca bildirim göndermeyecek şekilde susturun (silence).
