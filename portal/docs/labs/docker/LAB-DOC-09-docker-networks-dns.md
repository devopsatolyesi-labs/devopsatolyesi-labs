# LAB-DOC-09 — User-Defined Docker Network, Container DNS ve Servisler Arası İletişim

## Amaç

- Docker varsayılan (default) bridge ağı ile kullanıcı tanımlı (user-defined) bridge ağları arasındaki farkları kavramak.
- Kullanıcı tanımlı ağlarda çalışan otomatik DNS çözümleme (Embedded DNS Server) mekanizmasını deneyimlemek.
- Birden fazla konteyneri aynı ağa dahil ederek IP adresi yerine **konteyner ismi** ile haberleşmelerini sağlamak.
- `docker network` yaşam döngüsü komutlarını (`create`, `ls`, `inspect`, `connect`, `disconnect`, `rm`) uygulamalı öğrenmek.

---

## Ön Koşullar

Çalışma ortamınızda Docker servisinin çalıştığından emin olun:

```bash
docker version
```

> Komutlar hata vermeden tamamlanmalıdır. `8080` portunun boş olduğundan emin olun.

---

## Adımlar

### 1. Çalışma Dizinini ve Uygulama Dosyalarını Hazırlayın

Standart laboratuvar çalışma dizininizi oluşturun ve içine geçin:

```bash
mkdir -p ~/labs/LAB-DOC-09
cd ~/labs/LAB-DOC-09
```

Eğer laboratuvar paketini indirdiyseniz başlangıç dosyalarını kopyalayabilirsiniz:

```bash
cp -a starter/. . 2>/dev/null || true
```

Veya başlangıç dosyalarını doğrudan oluşturun:

```bash
cat <<'EOF' > app.py
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import os

BACKEND_HOST = os.getenv("BACKEND_HOST", "backend-service")
BACKEND_PORT = os.getenv("BACKEND_PORT", "80")

class NetworkHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"UP"}\n')
            return

        target_url = f"http://{BACKEND_HOST}:{BACKEND_PORT}/"
        try:
            req = urllib.request.Request(target_url)
            with urllib.request.urlopen(req, timeout=3) as response:
                content = response.read().decode('utf-8')
                self.send_response(200)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(f"Connected to backend ({BACKEND_HOST}): {content[:30]}...\n".encode('utf-8'))
        except Exception as e:
            self.send_response(502)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(f"Failed to connect to backend ({BACKEND_HOST}): {str(e)}\n".encode('utf-8'))

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), NetworkHandler)
    print("Frontend serving on port 8080...")
    server.serve_forever()
EOF
```

`Dockerfile` dosyasını oluşturun:

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

### 2. Kullanıcı Tanımlı Docker Ağı Oluşturun

Konteynerler arasında otomatik DNS çözümlemesi sağlayan izole bir bridge ağı oluşturun:

```bash
docker network create custom-app-net
docker network ls
```

---

### 3. Backend Servisini Başlatın

Arka planda hizmet verecek olan `backend-service` isimli Nginx konteynerini `custom-app-net` ağına bağlayarak başlatın:

```bash
docker run -d --name backend-service --network custom-app-net nginx:alpine
```

---

### 4. Frontend Servisini Derleyin ve Başlatın

Frontend imajını derleyin ve aynı ağa bağlayarak başlatın:

```bash
docker build -t lab-doc-09-frontend:v1 .
docker run -d --name frontend-service --network custom-app-net -p 8080:8080 \
  -e BACKEND_HOST="backend-service" -e BACKEND_PORT="80" lab-doc-09-frontend:v1
```

---

### 5. DNS Çözümlemesini ve Servisler Arası Erişimi Test Edin

Host üzerinden frontend servisine istek gönderin. Frontend servisi, `backend-service` ana makine adını (hostname) Docker dahili DNS'i üzerinden çözümleyip yanıtı getirecektir:

```bash
curl http://localhost:8080/
```

Ağ bağlantısını ve bağlı konteynerleri denetleyin:

```bash
docker network inspect custom-app-net --format '{{json .Containers}}' | jq .
```

---

## 💡 Docker Ağları ve DNS İnteraktif Pratik Alıştırmaları

#### Soru 1: Çalışan Konteyneri Sonradan Bir Ağa Bağlama
> **Görev:** `standalone-app` adında varsayılan bridge ağında bir konteyner başlatın, ardından onu `docker network connect` komutuyla `custom-app-net` ağına bağlayın.

??? tip "💡 Çözümü Göster"
    ```bash
    docker run -d --name standalone-app alpine sleep 3600
    docker network connect custom-app-net standalone-app
    docker network inspect custom-app-net | grep -A 3 standalone-app
    docker rm -f standalone-app
    ```

---

#### Soru 2: Konteyneri Bir Ağdan Ayırma
> **Görev:** `frontend-service` konteynerini `custom-app-net` ağından ayırın (`disconnect`) ve ağ durumunu kontrol edin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker network disconnect custom-app-net frontend-service
    curl http://localhost:8080/  # Hata (502) dönecektir çünkü artık backend'e erişemez!
    docker network connect custom-app-net frontend-service  # Tekrar bağlayın
    ```

---

#### Soru 3: Kullanılmayan Tüm Ağları Temizleme
> **Görev:** Hiçbir konteyner tarafından kullanılmayan tüm özel Docker ağlarını tek komutla temizleyin.

??? tip "💡 Çözümü Göster"
    ```bash
    docker network prune -f
    ```

---

## Beklenen Sonuç

```text
Connected to backend (backend-service): <!DOCTYPE html>
<html>
<head>
<t...
```

---

## Sorun Giderme

- **502 Bad Gateway:** `backend-service` konteynerinin çalıştığını `docker ps` ile teyit edin.
- **Ağ Çakışması:** `custom-app-net` zaten varsa `docker network rm custom-app-net` ile silip baştan oluşturun.
- **DNS Çözümleme Hatası:** Her iki konteynerin de aynı ağda (`custom-app-net`) olduğunu `docker network inspect custom-app-net` çıktısından doğrulayın.

---

## Kaynak

- [Hakan Bayraktar — Docker Commands Cheat Sheet with Examples](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f)
