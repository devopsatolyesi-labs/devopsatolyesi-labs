# LAB-DOC-15 — Docker Loglama ve Gözlemlenebilirlik

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `docker` | `8080`, `8081` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-15.zip)](/downloads/LAB-DOC-15.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Docker standart loglama sürücüsünü (`json-file`) ve log rotasyon mekanizmasını (`max-size`, `max-file`) yapılandırmak.
- Kontrolsüz log büyümesinin sunucu diskini doldurmasını (disk exhaustion) engellemek.
- `docker logs` parametrelerini (`--tail`, `--since`, `-f`, `--timestamps`) ileri düzeyde kullanmak.
- `docker events` ile Docker daemon üzerindeki olayları gerçek zamanlı dinlemek.
- `docker stats` ile CPU, bellek ve ağ I/O metriklerini canlı takip etmek.

---

## Ön Koşullar

- Docker Engine hazır olmalıdır.
- `8080` portu boş olmalıdır.

---

## Loglama ve Olay Mimarisi

```text
+-------------------------------------------------------------+
| KONTEYNER UYGULAMASI                                        |
|  - stdout / stderr akışlarına log yazar                     |
+-------------------------------------------------------------+
                               │
                               ▼
+-------------------------------------------------------------+
| DOCKER LOGGING DRIVER (json-file)                           |
|  - max-size: "10m" (Log dosyası 10MB'ı aşamaz)              |
|  - max-file: "3"   (En fazla 3 arşiv dosyası tutulur)       |
|  - Toplam Disk Güvencesi: Maksimum 30 MB!                   |
+-------------------------------------------------------------+
                               │
       ┌───────────────────────┴───────────────────────┐
       ▼                                               ▼
[ docker logs CLI ]                             [ docker events ]
- Canlı takip (-f)                              - container create/die
- Zaman damgası (-t)                            - health status events
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-15
cd ~/labs/LAB-DOC-15
```

---

### Adım 2: Log Rotasyonu Tanımlı `docker-compose.yml` Hazırlayın

```bash
cat <<'EOF' > docker-compose.yml
services:
  log-generator:
    image: alpine:3.19
    container_name: log-producer
    command: >
      sh -c '
        count=1;
        while true; do
          echo "{"timestamp":"$(date -u +%FT%TZ)", "level":"INFO", "iteration":$$count, "message":"Heartbeat event logged successfully"}";
          count=$$((count + 1));
          sleep 1;
        done
      '
    logging:
      driver: "json-file"
      options:
        max-size: "1m"
        max-file: "3"
    restart: unless-stopped
EOF
```

---

### Adım 3: Konteyneri Başlatın ve Log Akışını Filtreleyin

```bash
docker compose up -d
```

Logları farklı bayraklarla inceleyin:

```bash
# 1. Son 5 log satırını zaman damgasıyla gösterin
docker logs --tail 5 --timestamps log-producer

# 2. Sadece son 30 saniyedeki logları alın
docker logs --since 30s log-producer
```

---

### Adım 4: Gerçek Zamanlı Olayları Dinleyin (Docker Events)

Ayrı bir arka plan süreciyle Docker daemon olaylarını izleyin:

```bash
# Arka planda olayları dinleyin
docker events --filter 'container=log-producer' --format 'Type={{.Type}} Action={{.Action}} Time={{.Time}}' &
EVENTS_PID=$!

# Konteyneri durdurup tekrar başlatın
docker compose stop log-producer
docker compose start log-producer

sleep 2
kill $EVENTS_PID 2>/dev/null || true
```

Terminalde `Action=stop`, `Action=die`, `Action=start` olaylarının yakalandığını görün.

---

### Adım 5: Canlı Performans Metriklerini İzleyin

```bash
docker stats --no-stream --format "table {{.Name}}	{{.CPUPerc}}	{{.MemUsage}}	{{.NetIO}}" log-producer
```

---

### Adım 6: Fiziksel Log Dosyasını ve Boyutunu İnceleyin

Konteynerin host diskinde nerede depolandığını `docker inspect` ile bulun:

```bash
LOG_PATH=$(docker inspect --format='{{.LogPath}}' log-producer)
echo "Fiziksel Log Dosyası: $LOG_PATH"
sudo ls -lh "$LOG_PATH" 2>/dev/null || ls -lh "$LOG_PATH" 2>/dev/null || true
```

---

## Doğal Doğrulama

```bash
# JSON formatında geçerli log üretildiğini doğrulayın
docker logs --tail 1 log-producer | grep -q "Heartbeat event" && echo "Log akışı BAŞARILI"
```

---

### Adım 7: Temizlik

```bash
docker compose down
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Docker varsayılanında `max-size` ve `max-file` log rotasyon parametreleri ayarlanmazsa ne olur?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Varsayılan olarak Docker'ın `json-file` sürücüsünde hiçbir boyut sınırı yoktur. Çok log üreten bir konteyner haftalarca çalıştığında gigabaytlarca JSON log dosyası birikir ve sunucunun kök diskini (`/var/lib/docker`) tamamen doldurarak tüm işletim sisteminin kilitlenmesine yol açar.

??? question "Soru 2: Sistem genelinde tüm konteynerler için geçerli olacak bir log rotasyonu nasıl yapılandırılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `/etc/docker/daemon.json` dosyası içerisine varsayılan loglama sürücüsü ve ayarları eklenip Docker servisi yeniden başlatılır (`sudo systemctl restart docker`):
        ```json
        {
          "log-driver": "json-file",
          "log-opts": {
            "max-size": "10m",
            "max-file": "3"
          }
        }
        ```

---

## Beklenen Sonuç

- `docker logs --tail 5` komutunun geçerli JSON formatlı loglar listelemesi.
- `docker events` komutunun konteyner durdurma/başlatma anında olay tetiklemesi.
