# LAB-DOC-01 — Docker Engine Verification, First Container & Port Mapping

## Metadata
- **Seviye:** CORE
- **Önerilen Gün:** Gün 1
- **Tahmini Süre:** 30 dk
- **Gerekli Profil:** `docker`
- **Host Portları:** `8080:80`
- **Çalışma Dizini:** `~/devops-workspace/labs/LAB-DOC-01`

---

## 1. Lab Senaryosu
Mikroservis mimarisine geçiş yapan bir kurumda, geliştirilen servislerin fiziksel sunucu bağımlılıklarından kurtarılması ve izole ortamlarda çalıştırılması hedeflenmektedir. Bu doğrultuda sunucu üzerindeki Docker Engine çalışma durumu teyit edilmeli, ilk OCI tabanlı web servisi ayağa kaldırılmalıdır. Konteynerin dış dünyaya açılabilmesi için host ve konteyner arasındaki port yönlendirme mekanizması kurgulanacak, erişim logları takip edilerek servis yaşam döngüsü doğrulanacaktır.

## 2. Amaç
Docker CLI ve Daemon durumunu doğrulamak, arka planda (`-d`) port haritalamalı (`-p 8080:80`) Nginx web sunucusu çalıştırmak, canlı log akışını izlemek ve konteyner yaşam döngüsünü yönetmek.

## 3. Mimari / Akış
```text
  [ Host: Ubuntu 24.04 ] (Port: 8080)
            |
            v  (Port Mapping: 8080 -> 80)
  [ Container: my-first-web (nginx:1.27-alpine) ]
            |
            +---> Serving HTTP Port 80 (/usr/share/nginx/html)
```

## 4. Ön Koşullar
- Docker Engine kurulu ve çalışır durumda olmalıdır
- Kullanıcı `docker` grubuna üye olmalıdır
- Host üzerinde 8080 portu boş olmalıdır

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
docker --version
docker info --format '{{.ServerVersion}}'
sudo systemctl is-active docker
```

## 5. Adım Adım Uygulama

### Adım 1 — Çalışma Dizinini Hazırlama
Laboratuvar çalışma dizinini oluşturun:
```bash
mkdir -p ~/devops-workspace/labs/LAB-DOC-01
cd ~/devops-workspace/labs/LAB-DOC-01
```

### Adım 2 — Konteyneri Arka Planda Başlatma
Nginx web sunucusunu arka planda (`detached`), `my-first-web` adıyla ve 8080 host portuna yönlendirerek başlatın:
```bash
docker run -d \
  --name my-first-web \
  -p 8080:80 \
  nginx:1.27-alpine
```

### Adım 3 — Çalışan Konteyneri ve Port Haritasını Denetleme
Konteynerin durumunu listeleyin:
```bash
docker ps --filter "name=my-first-web"
```

### Adım 4 — HTTP İsteği ile Servisi Test Etme ve Logları İnceleme
Host üzerinden web servisine HTTP isteği gönderin ve erişim loglarını görüntüleyin:
```bash
# HTTP isteği gönder
curl -i http://localhost:8080

# Konteyner erişim loglarını incele
docker logs --tail 10 my-first-web
```

## 6. Beklenen Sonuç
Adım 3'teki konteyner listesi çıktısı:
```text
CONTAINER ID   IMAGE               COMMAND                  PORTS                  NAMES
...            nginx:1.27-alpine   "/docker-entrypoint.…"   0.0.0.0:8080->80/tcp   my-first-web
```

Adım 4'teki HTTP yanıtı ve log çıktısı:
```text
HTTP/1.1 200 OK
Server: nginx/...
...
GET / HTTP/1.1" 200 ...
```

## 7. Doğrulama
Web servisinin port 8080 üzerinden HTTP 200 yanıtı döndürdüğünü doğrulayın:
```bash
if curl -sf http://localhost:8080 | grep -q "Welcome to nginx"; then
  echo "VALIDATION SUCCESS: Docker container is active and serving HTTP on port 8080."
else
  echo "VALIDATION FAILED: Unable to reach web service on port 8080." && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
`docker run` komutu verildiğinde `Got permission denied while trying to connect to the Docker daemon socket` hatası alınır.

### Kanıt
Socket dosya izinlerinde kullanıcının erişim hakkı olmadığı görülür.

### Kontrol Komutu
```bash
ls -la /var/run/docker.sock
groups
```

### Muhtemel Neden
Geçerli kullanıcı `docker` grubuna dahil değildir veya yeni eklenen grup üyeliği mevcut oturuma yüklenmemiştir.

### Çözüm
Kullanıcıyı gruba ekleyin ve grup oturumunu yenileyin:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Tekrar Doğrulama
```bash
docker ps
# Hata almadan çalışan konteyner tablosu listelenmelidir.
```

## 9. Temizlik / Sıfırlama
Konteyneri durdurun ve sistemden silin:
```bash
docker rm -f my-first-web 2>/dev/null || true
rm -rf ~/devops-workspace/labs/LAB-DOC-01
```

## 10. Production Notu
Üretim ortamlarında konteynerler rastgele isimlerle başlatılmaz; mikroservis adı ve ortam bilgisi içeren isimlendirme standartları (`--name order-api-prod`) uygulanır. Ayrıca beklenmeyen çökmelere karşı `--restart unless-stopped` politikası tanımlanmalı ve logların disk doldurmasını önlemek amacıyla `--log-opt max-size=10m --log-opt max-file=3` gibi log rotasyon kuralları konulmalıdır.

## 11. Challenge
Konteynerin iç kök dosya sistemindeki `/usr/share/nginx/html/index.html` dosyasını `docker cp` veya `docker exec` komutuyla güncelleyerek tarayıcıda özel bir karşılama metni görüntüleyin.
