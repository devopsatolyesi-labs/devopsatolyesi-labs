# LAB-DOC-07 — İlk Dockerfile ile İmaj Oluşturma

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `docker` | `5000` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-07.zip)](/downloads/LAB-DOC-07.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 40 dakika | `docker` | `5000` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-07.zip)](/downloads/LAB-DOC-07.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Dockerfile direktiflerinin (`FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`, `CMD`) işlevlerini ve yaşam döngüsünü kavramak.
- Python Flask tabanlı bir mikroservisi Dockerfile kullanarak imaj haline getirmek (`docker build`).
- `.dockerignore` dosyasının build context ve imaj boyutu üzerindeki kritik rolünü test etmek.
- `CMD` ile `ENTRYPOINT` arasındaki farkları ve override davranışlarını deneyimlemek.
- Üretilen imajı yerel olarak çalıştırıp HTTP API üzerinden doğrulamak.

---

## Ön Koşullar

- Docker Engine servisinin çalışır durumda olması.
- Host üzerinde `5000` portunun boş olması.

---

## Dockerfile Mimarisi ve Build Context

```text
[ Proje Kaynak Dizini (Build Context) ]
  ├── app.py
  ├── requirements.txt
  ├── .dockerignore  (venv, git, log dosyalarını context dışı bırakır)
  └── Dockerfile
          │
          │  docker build -t order-api:1.0 .
          ▼
+-------------------------------------------------------------+
| DOCKER DAEMON & BUILD MOTORU                                |
|  1. FROM python:3.11-slim (Temel işletim sistemi ve runtime)|
|  2. WORKDIR /app          (Çalışma dizini ayarı)            |
|  3. COPY requirements.txt (Bağımlılık listesi)              |
|  4. RUN pip install ...   (Paket kurulumu)                  |
|  5. COPY app.py           (Uygulama kaynak kodu)            |
|  6. ENV PORT=5000         (Varsayılan ortam değişkeni)      |
|  7. EXPOSE 5000           (Belgeleme portu)                 |
|  8. CMD ["python", "app.py"] (Varsayılan başlatma komutu)   |
+-------------------------------------------------------------+
          │
          ▼
[ İmaj: order-api:1.0 (~140MB) ] ---> docker run -p 5000:5000
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-07
cd ~/labs/LAB-DOC-07
```

---

### Adım 2: Örnek Python Flask Mikroservisini Hazırlayın

Basit, sistem durumunu ve ortam değişkenlerini JSON olarak dönen bir Flask uygulaması yazın:

```bash
cat <<'EOF' > app.py
import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({
        "service": "Order Management API",
        "version": "1.0.0",
        "hostname": socket.gethostname(),
        "environment": os.getenv("APP_ENV", "development"),
        "status": "healthy"
    })

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
EOF
```

Bağımlılık dosyasını oluşturun:

```bash
cat <<'EOF' > requirements.txt
Flask==3.0.2
Werkzeug==3.0.1
EOF
```

---

### Adım 3: `.dockerignore` Dosyasını Tanımlayın

Docker daemon'a gereksiz dosya transferini engellemek için `.dockerignore` hazırlayın:

```bash
cat <<'EOF' > .dockerignore
__pycache__
*.pyc
*.pyo
*.pyd
.git
.gitignore
.env*
node_modules
*.log
README.md
EOF
```

---

### Adım 4: Standart Dockerfile Dosyasını Yazın

```bash
cat <<'EOF' > Dockerfile
# 1. Aşama: Resmi hafif Python taban imajı
FROM python:3.11-slim

# 2. Çalışma dizini belirleme
WORKDIR /app

# 3. Bağımlılıkları kopyalama ve yükleme (Önbellek avantajı)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Kaynak kodları kopyalama
COPY app.py .

# 5. Ortam değişkenleri ve port tanımları
ENV APP_ENV=production     PORT=5000

EXPOSE 5000

# 6. Konteyner başlangıç komutu
CMD ["python", "app.py"]
EOF
```

---

### Adım 5: İmajı Derleyin (Build)

İmajı `order-api:1.0` etiketiyle derleyin:

```bash
docker build -t order-api:1.0 .
```

Derlenen imajı ve katmanlarını listeleyin:

```bash
docker images order-api:1.0
docker history order-api:1.0
```

---

### Adım 6: Konteyneri Başlatın ve Test Edin

```bash
docker run -d --name my-order-api -p 5000:5000 order-api:1.0
```

---

## Doğal Doğrulama

Konteynerin çalıştığını ve HTTP API'nin yanıt verdiğini CLI üzerinden doğrulayın:

```bash
# 1. Konteyner durumunu kontrol edin
docker ps --filter name=my-order-api

# 2. HTTP GET isteği gönderin
curl -s http://localhost:5000 | jq . || curl -s http://localhost:5000

# 3. Konteyner loglarını inceleyin
docker logs my-order-api
```

`service: "Order Management API"` ve `status: "healthy"` içeren JSON yanıtını görmelisiniz.

---

### Adım 7: Temizlik

```bash
docker rm -f my-order-api
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Dockerfile içinde `CMD` ile `ENTRYPOINT` arasındaki en temel fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `ENTRYPOINT` konteynerin değişmez ana yürütülebilir ikili dosyasını (executable) tanımlar. `CMD` ise bu ana komuta varsayılan argümanları sağlar. `docker run <image> arg1` çalıştırıldığında `CMD` ezilir (override edilir), ancak `ENTRYPOINT` (`--entrypoint` bayrağı açıkça kullanılmadıkça) sabit kalır.

??? question "Soru 2: Neden `COPY . .` yerine önce `COPY requirements.txt .` ve `RUN pip install` satırlarını yazıyoruz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        **Docker Layer Cache (Katman Önbelleği)** verimliliği için. Kaynak kodunuz (`app.py`) sürekli değişirken `requirements.txt` nadiren güncellenir. Eğer bağımlılıkları önce yüklerseniz, kodunuzdaki küçük bir değişiklikte Docker `pip install` katmanını önbellekten anında çeker ve derleme süresi saniyelere iner.

??? question "Soru 3: `.dockerignore` dosyası kullanılmazsa ne tür problemler ortaya çıkar?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        1. `.git`, yerel test veritabanları veya sanal ortamlar (`venv/`) gigabaytlarca boyuta sahip olabilir; derleme başladığında daemon'a aktarılmaları dakikalar sürer.
        2. Yerel `.env` dosyaları veya hassas SSH anahtarları kazara konteyner imajının içine kopyalanıp imaj deposuna sızabilir.

---

## Beklenen Sonuç

```json
{
  "environment": "production",
  "hostname": "a1b2c3d4e5f6",
  "service": "Order Management API",
  "status": "healthy",
  "version": "1.0.0"
}
```

---

## Sorun Giderme

- **Modül Bulunamadı (No module named 'flask'):** `requirements.txt` dosyasının `pip install` komutundan önce kopyalandığından emin olun.
- **Port 5000 Meşgul (Address already in use):** MacOS sistemlerinde AirPlay Receiver varsayılan olarak 5000 portunu kullanabilir. Bu durumda `docker run -p 5001:5000` kullanıp `curl localhost:5001` ile test edin.
