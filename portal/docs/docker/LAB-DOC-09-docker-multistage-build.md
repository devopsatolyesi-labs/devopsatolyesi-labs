# LAB-DOC-09 — Multi-Stage Build ve Boyut Optimizasyonu

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `docker` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-09.zip)](/downloads/LAB-DOC-09.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `docker` | `8080` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-DOC-09.zip)](/downloads/LAB-DOC-09.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Geliştirme/derleme araçlarını (compiler, SDK, paket yöneticileri) üretim (production) çalışma ortamından izole etmek.
- İki veya daha fazla aşamalı Dockerfile (`FROM ... AS builder` ve `FROM ... AS runtime`) kurgulamak.
- Derlenen statik ikili dosyayı (Go binary) minimal `scratch` veya `alpine` tabanına aktararak imaj boyutunu ~800MB'tan ~15MB'a düşürmek.
- İmaj boyutunu küçülterek saldırı yüzeyini (attack surface) ve ağ transfer süresini minimize etmek.

---

## Ön Koşullar

- Docker Engine çalışır durumda olmalıdır.
- `8080` portu boş olmalıdır.

---

## Multi-Stage Mimari Şeması

```text
+-------------------------------------------------------------+
| 1. AŞAMA: BUILDER (golang:1.22-alpine AS builder)           |
|  - Go derleyici, build araçları, git ve kaynak kodlar var.  |
|  - CGO_ENABLED=0 go build ile statik tek bir ikili dosya    |
|    (/app/server) üretilir.                                  |
|  - Aşama Boyutu: ~300 MB                                    |
+-------------------------------------------------------------+
                               │
            SADECE DERLENEN /app/server AKTARILIR
            (COPY --from=builder /app/server /server)
                               ▼
+-------------------------------------------------------------+
| 2. AŞAMA: PRODUCTION RUNTIME (alpine:3.19 veya scratch)     |
|  - İçinde derleyici, go komutları veya kaynak kodlar YOK!   |
|  - Sadece /server ikili dosyası ve kısıtlı kullanıcı var.   |
|  - Nihai İmaj Boyutu: ~12 MB!                               |
+-------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-DOC-09
cd ~/labs/LAB-DOC-09
```

---

### Adım 2: Yüksek Performanslı Go Web Servisini Yazın

```bash
cat <<'EOF' > main.go
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

type Response struct {
	Service string `json:"service"`
	Version string `json:"version"`
	Runtime string `json:"runtime"`
}

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	res := Response{
		Service: "Payment Microservice",
		Version: "2.4.0",
		Runtime: "Multi-Stage Minimal Binary",
	}
	json.NewEncoder(w).Encode(res)
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	http.HandleFunc("/", handler)
	fmt.Printf("Payment service running on port %s...
", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF
```

---

### Adım 3: Tek Aşamalı (Single-Stage) Şişkin İmajı Derleyin

Önce multi-stage kullanmadan tüm SDK'yı içeren geleneksel bir imaj oluşturalım:

```bash
cat <<'EOF' > Dockerfile.single
FROM golang:1.22-alpine
WORKDIR /app
COPY main.go .
RUN go build -o server main.go
EXPOSE 8080
CMD ["./server"]
EOF

docker build -f Dockerfile.single -t payment-api:bloated .
```

İmaj boyutunu inceleyin:

```bash
docker images payment-api:bloated
```

Boyutun yaklaşık **300-350 MB** olduğunu göreceksiniz.

---

### Adım 4: Multi-Stage Dockerfile Yazın ve Boyutu Optimize Edin

Şimdi iki aşamalı (builder ve runtime) Dockerfile hazırlayın:

```bash
cat <<'EOF' > Dockerfile.multistage
# 1. Aşama: Derleme (Builder)
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY main.go .

# CGO_ENABLED=0 ile tamamen bağımsız statik ikili dosya üretin
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /out/server main.go

# 2. Aşama: Minimal Üretim Ortamı (Runtime)
FROM alpine:3.19
WORKDIR /app

# Güvenlik için non-root kullanıcı
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# SADECE derlenmiş ikili dosyayı builder aşamasından kopyalayın
COPY --from=builder /out/server /app/server

USER appuser
EXPOSE 8080

CMD ["/app/server"]
EOF
```

---

### Adım 5: Multi-Stage İmajı Derleyin ve Karşılaştırın

```bash
docker build -f Dockerfile.multistage -t payment-api:optimized .
```

İki imajın boyutunu yan yana kıyaslayın:

```bash
docker images --filter reference=payment-api:*
```

Farkı göreceksiniz:
- `payment-api:bloated`: ~320 MB
- `payment-api:optimized`: ~13 MB (Yaklaşık **%96 boyut tasarrufu!**)

---

## Doğal Doğrulama

Minimal imajdan konteyneri başlatın ve çalışmasını doğrulayın:

```bash
docker run -d --name payment-service -p 8080:8080 payment-api:optimized
curl -s http://localhost:8080
docker ps --filter name=payment-service
```

HTTP yanıtında `Runtime: "Multi-Stage Minimal Binary"` ve `200 OK` alındığını doğrulayın.

---

### Adım 6: Temizlik

```bash
docker rm -f payment-service
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Go derleme komutundaki `-ldflags="-w -s"` parametreleri ne işe yarar?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `-w` debug sembollerini (DWARF), `-s` ise sembol tablosunu ikili dosyadan ayıklar (strip eder). Programın çalışmasında hiçbir fark yaratmaz; ancak ikili dosya boyutunu %30-40 oranında küçülterek Docker imajını daha da hafifletir.

??? question "Soru 2: İkinci aşamada `FROM scratch` kullanmak mümkün müdür ve ne zaman tercih edilir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Evet, mümkündür. `scratch`, Docker'ın sıfır baytlık tamamen boş temel imajıdır. `CGO_ENABLED=0` ile derlenen bağımsız Go/Rust binary'leri işletim sistemi kabuğuna (shell) dahi ihtiyaç duymadığı için doğrudan `scratch` üzerine kopyalanabilir. Bu durumda nihai imaj boyutu sadece ikili dosyanın boyutu kadar (~8 MB) olur. Tek dezavantajı içinde `sh` veya `curl` olmadığı için `docker exec` ile içine girilemez.

??? question "Soru 3: Multi-stage bir Dockerfile'da belirli bir aşamayı tek başına nasıl derleyebiliriz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `docker build --target builder -t my-builder:dev .` komutu ile `--target` bayrağı kullanılarak sadece hedeflenen aşama derlenebilir.

---

## Beklenen Sonuç

```text
REPOSITORY    TAG         SIZE
payment-api   optimized   ~13.5MB
payment-api   bloated     ~320MB
```

---

## Sorun Giderme

- **Exec format error:** Go ikili dosyasını derlerken `GOOS=linux` bayrağının verildiğinden emin olun (host MacOS/ARM olsa dahi konteyner Linux çekirdeğinde çalışır).
