# LAB-DOC-01 — İlk Docker Konteyneri ve Yaşam Döngüsü

## Amaç

- Docker Engine ortamının çalıştığını doğrulamak.
- Konteyner yaşam döngüsünü (`run`, `ps`, `logs`, `inspect`, `exec`, `stop`, `start`, `rm`) uygulamalı olarak öğrenmek.
- Basit bir Python HTTP uygulamasını `Dockerfile` ile paketleyip port yönlendirmesi (`-p 8080:8080`) ile çalıştırmak.
- İnteraktif Docker temel komut alıştırmalarını çözmek.

---

## Ön Koşullar

Çalışma ortamınızda Docker servisinin çalıştığından ve gerekli izinlere sahip olduğunuzdan emin olun:

```bash
docker version
docker info >/dev/null
```

> Komutlar hata vermeden tamamlanmalıdır. `8080` portunun boş olduğundan emin olun.

---

## Adımlar

### 1. Çalışma Dizinini Hazırlayın

Standart laboratuvar çalışma dizininizi oluşturun ve içine geçin:

```bash
mkdir -p ~/labs/LAB-DOC-01
cd ~/labs/LAB-DOC-01
```

Eğer laboratuvar paketini indirdiyseniz başlangıç dosyalarını kopyalayabilirsiniz:

```bash
cp -a starter/. . 2>/dev/null || true
```

Veya başlangıç dosyalarını doğrudan oluşturun:

```bash
cat <<'EOF' > app.py
# LAB-DOC-01 Starter App
from http.server import HTTPServer, BaseHTTPRequestHandler

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain; charset=utf-8')
        self.end_headers()
        self.wfile.write(b"Hello from DevOps Atolyesi LAB-DOC-01!\n")

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), SimpleHandler)
    print("Serving on port 8080...")
    server.serve_forever()
EOF
```

---

### 2. Dockerfile Dosyasını Oluşturun

Uygulamayı konteynerize etmek için `Dockerfile` dosyasını oluşturun:

```bash
cat <<'EOF' > Dockerfile
FROM python:3.11-alpine
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python", "app.py"]
EOF
```

---

### 3. İmajı Derleyin ve Konteyneri Başlatın

İmajı `devops-first-container:v1` etiketiyle derleyin:

```bash
docker build -t devops-first-container:v1 .
```

Konteyneri arka planda (`-d`), `lab-doc-01-test` ismiyle ve host'un `8080` portunu konteynerin `8080` portuna bağlayarak çalıştırın:

```bash
docker run -d --name lab-doc-01-test -p 8080:8080 devops-first-container:v1
```

---

### 4. Konteyner Durumunu ve Yanıtı Kontrol Edin

Çalışan konteyneri listeleyin:

```bash
docker ps --filter name=lab-doc-01-test
```

HTTP servisine istek atarak yanıtı doğrulayın:

```bash
curl http://localhost:8080
```

Konteynerin loglarını inceleyin:

```bash
docker logs --tail 10 lab-doc-01-test
```

---

### 5. Konteyner İçinde Komut Çalıştırma ve İnceleme (Exec & Inspect)

Konteynerin IP adresini ve durumunu JSON formatında inceleyin:

```bash
docker inspect --format '{{ .NetworkSettings.IPAddress }}' lab-doc-01-test
```

Konteyner içine bağlanarak süreçleri kontrol edin:

```bash
docker exec -it lab-doc-01-test ps aux
```

---

## 💡 Temel Docker Komutları İnteraktif Pratik Alıştırmaları

Aşağıdaki görevleri kendi terminalinizde deneyin. Yanıtınızı kontrol etmek için ipucu kutucuğuna tıklayın.

#### Soru 1: Arka Planda Nginx Başlatma
> **Görev:** `nginx:alpine` imajını kullanarak `web-test` adında, host `8085` portunu konteynerin `80` portuna yönlendiren bir konteyneri arka planda başlatın.

??? tip "💡 Çözümü Göster"
    ```bash
    docker run -d --name web-test -p 8085:80 nginx:alpine
    curl http://localhost:8085
    ```

---

#### Soru 2: Konteyner İçine İnteraktif Kabuk (Shell) ile Bağlanma
> **Görev:** Çalışan `web-test` konteynerinin içine `sh` kabuğu ile bağlanıp `/etc/nginx/nginx.conf` dosyasını görüntüleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker exec -it web-test sh
    # Konteyner içinde:
    cat /etc/nginx/nginx.conf
    exit
    ```

---

#### Soru 3: Konteyner Loglarını Canlı Takip Etme
> **Görev:** `lab-doc-01-test` konteynerinin loglarını canlı akış (follow) modunda izleyin ve son 5 satırı görüntüleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker logs -f --tail 5 lab-doc-01-test
    # Çıkış için: Ctrl + C
    ```

---

#### Soru 4: Konteyneri Durdurma ve Yeniden Başlatma
> **Görev:** `web-test` konteynerini durdurun, durdurulduğunu teyit edin ve ardından tekrar başlatın.

??? tip "💡 Çözümü Göster"
    ```bash
    docker stop web-test
    docker ps -a --filter name=web-test
    docker start web-test
    ```

---

#### Soru 5: Kullanılmayan Kaynakları Temizleme
> **Görev:** Durdurulmuş konteynerleri ve kullanılmayan ağları tek komutla temizleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker container prune -f
    ```

---

## Beklenen Sonuç

```text
Hello from DevOps Atolyesi LAB-DOC-01!
```

---

## Sorun Giderme

- **Permission Denied Hatası:** Kullanıcınızın `docker` grubunda olduğunu `groups` komutuyla kontrol edin. Değilseniz `sudo usermod -aG docker $USER` komutunu çalıştırıp yeni oturum açın.
- **Port Çakışması:** `8080` portu kullanımda ise `docker ps --filter publish=8080` komutu ile çakışan konteyneri bulun ve durdurun.
- **İmaj Derleme Hatası:** `Dockerfile` dosyasında `COPY app.py .` satırının ve dosya isimlerinin doğruluğunu kontrol edin.

---

## Kaynak

- [Hakan Bayraktar — Docker Commands Cheat Sheet with Examples](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f)
