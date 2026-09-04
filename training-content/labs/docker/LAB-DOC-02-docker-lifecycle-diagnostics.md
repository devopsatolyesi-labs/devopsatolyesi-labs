# LAB-DOC-02 — Konteyner Yaşam Döngüsü ve Teşhis Komutları

## Metadata

- **Seviye:** CORE
- **Süre:** 40 dakika
- **Profil:** `docker`
- **Port:** `8081`

## Amaç

- Konteyner yaşam döngüsü durumlarını (`created`, `running`, `paused`, `stopped`, `exited`) uygulamalı olarak deneyimlemek.
- `docker exec -it` ile çalışan konteyner içine interaktif kabuk (shell) açıp sorun teşhisi yapmak.
- `docker logs` komutu ile stdout/stderr çıktılarını canlı (`-f`) ve filtrelenmiş (`--tail`) olarak izlemek.
- `docker inspect` ile konteynerin IP adresi, port eşlemesi ve ortam değişkenlerini JSON formatında sorgulamak.
- `docker stats` ile gerçek zamanlı CPU, RAM ve ağ I/O tüketimini ölçmek.
- Çıkış kodlarını (`exit code 0`, `exit 1` ve `exit 137 OOMKilled`) incelemek.

---

## Ön Koşullar

- Docker Engine ortamının hazır olması.
- `8081` portunun boş olması.

---

## Konteyner Durum Makinesi (State Machine)

```text
               +-------------------------------------------+
               |                                           |
               v                                           |
+---------+  docker create/run  +---------+  docker stop   |
|  IMAGE  | ------------------> | RUNNING | -------------> +
+---------+                     +---------+                |
                                  |     ^                  v
                     docker pause |     | docker unpause +--------+
                                  v     |                | EXITED |
                                +---------+              +--------+
                                | PAUSED  |                |
                                +---------+                v
                                                     docker rm (Silindi)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-02
cd ~/labs/LAB-DOC-02
```

---

### Adım 2: Test Konteynerini Başlatın

Arka planda çalışan bir HTTP konteyneri oluşturun:

```bash
docker run -d --name diagnostics-demo -p 8081:80 nginx:alpine
```

---

### Adım 3: Canlı Logları İzleyin (Logs)

Konteyner loglarını canlı akış modunda (`-f`) takip edin:

```bash
# Ayrı bir terminalde veya arka planda çalıştırabilirsiniz
docker logs -f --tail 10 diagnostics-demo &
LOG_PID=$!

# Konteynere birkaç istek gönderin
curl -s http://localhost:8081/ >/dev/null
curl -s http://localhost:8081/not-found >/dev/null

# Log takibini durdurun
kill $LOG_PID 2>/dev/null || true
```

Log çıktısında `200 OK` ve `404 Not Found` erişim satırlarının Nginx stdout'una düştüğünü görün.

---

### Adım 4: Konteyner İçine Bağlanın (Exec)

Çalışan konteyner içinde yeni bir süreç (process) başlatıp dosya sistemini inceleyin:

```bash
# Konteyner içinde dosya oluşturma
docker exec diagnostics-demo sh -c "echo 'DevOps Atolyesi Diagnostics Test' > /usr/share/nginx/html/test.txt"

# Oluşturulan dosyayı host üzerinden HTTP ile doğrulayın
curl -s http://localhost:8081/test.txt
```

---

### Adım 5: Konteyner Metadata Sorgulama (Inspect)

Konteynerin IP adresini ve çalışma durumunu `--format` kullanarak JSON içinden çekin:

```bash
# Konteyner IP adresi
docker inspect --format '{{ .NetworkSettings.IPAddress }}' diagnostics-demo

# Konteyner PID (ana makinedeki gerçek process ID)
docker inspect --format '{{ .State.Pid }}' diagnostics-demo

# Konteyner çalışma durumu
docker inspect --format '{{ .State.Status }}' diagnostics-demo
```

---

### Adım 6: Kaynak Tüketimini İnceleyin (Stats)

Konteynerin CPU ve RAM kullanımını anlık olarak raporlayın:

```bash
docker stats --no-stream diagnostics-demo
```

---

### Adım 7: Çıkış Kodları ve Anlamları (Exit Codes)

Linux ve Docker'da her sürecin bir çıkış kodu (exit code) bulunur:

```bash
# Başarılı çıkış (Exit Code 0)
docker run --rm alpine sh -c "exit 0"
echo "Son çıkış kodu: $?"

# Hata ile çıkış (Exit Code 1)
docker run --rm alpine sh -c "exit 1" || echo "Beklenen hata kodu: $?"

# Zorla öldürülme / OOMKilled (Exit Code 137: 128 + 9 SIGKILL)
docker run -d --name crash-test alpine sleep 100
docker kill crash-test
docker inspect --format '{{ .State.ExitCode }}' crash-test
docker rm crash-test
```

> **Önemli Bilgi:** `Exit Code 137`, sürecin `SIGKILL (Signal 9)` ile öldürüldüğünü gösterir (128 + 9 = 137). Kubernetes ve Docker'da OOMKilled (Out Of Memory) olan konteynerler daima `137` koduyla sonlanır!

---

### Adım 8: Temizlik

```bash
docker rm -f diagnostics-demo
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: `docker stop` ile `docker kill` arasındaki teknik fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `docker stop`, konteyner içindeki ana sürece önce `SIGTERM (15)` sinyali gönderir ve sürecin açık bağlantıları, dosyaları düzgünce kapatması (graceful shutdown) için 10 saniye bekler. Süre dolarsa `SIGKILL (9)` yollar. `docker kill` ise hiç beklemeden doğrudan `SIGKILL (9)` göndererek süreci anında zorla sonlandırır.

??? question "Soru 2: Bir konteyner `docker run -d alpine` komutuyla başlatıldığında neden hemen durur (`Exited (0)`)?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Bir konteyner, Dockerfile'daki ana süreci (`PID 1`) çalıştığı sürece ayakta kalır. `alpine` imajının varsayılan komutu `sh` kabuğudur. Arka planda (`-d`) stdin/tty bağlı olmadan başlatıldığında `sh` anında EOF alır ve `exit 0` ile sonlanır. Ayakta tutmak için `-it` bayrağıyla veya sürekli çalışan bir komutla (`sleep infinity`) başlatılmalıdır.

??? question "Soru 3: Üretim ortamında çalışan bir konteynerde `docker inspect` ile sadece sağlık durumunu (health status) tek satırda nasıl okuruz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Go template formatı kullanarak:
        ```bash
        docker inspect --format '{{ .State.Health.Status }}' <container_name>
        ```

---

## Beklenen Sonuç

- `curl http://localhost:8081/test.txt` komutu `DevOps Atolyesi Diagnostics Test` yanıtını döner.
- `docker inspect` komutları IP adresi ve PID değerini tek satırda listeler.
- `crash-test` konteyneri `137` çıkış kodunu üretir.

---

## Sorun Giderme

- **Log Takibi Askıda Kalırsa:** Terminalde `Ctrl + C` tuşlayarak log akışından çıkabilirsiniz.
- **Port 8081 Meşgulse:** `docker ps --filter publish=8081` ile çalışan eski konteyneri tespit edip silin.
