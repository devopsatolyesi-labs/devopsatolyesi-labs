# LAB-K8S-05 — Service, Port Mapping ve Kubernetes DNS

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `kubernetes`, `kubectl` | `8080`, `80` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-05.zip)](/downloads/LAB-K8S-05.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Kubernetes Pod'larının dinamik ve değişken IP adreslerini sabit bir servis arkasında soyutlamak (**Service Abstraction**).
- **ClusterIP** ve **NodePort** servis türlerini uygulamalı olarak yapılandırmak.
- Service `selector` ile Pod `labels` ilişkisini ve otomatik oluşan **Endpoints** nesnesini incelemek.
- CoreDNS üzerinden servis isim çözümlemesini (`curl http://backend-service`) test etmek.
- Hatalı selector nedeniyle oluşan bağlantı kesintisini (`<none>` endpoint) tespit edip düzeltmek.

---

## Ön Koşullar

- Kind kümesi aktif olmalıdır.

---

## Service, Endpoints ve CoreDNS Mimarisi

```text
[ İSTEMCİ POD (curl-client) ]
          │
          │ 1. DNS Sorgusu: "backend-service" kime ait?
          ▼
[ CoreDNS (kube-dns) ] ───► Çözer: 10.96.120.45 (ClusterIP)
          │
          │ 2. HTTP İsteği: http://backend-service:80
          ▼
[ SERVICE (backend-service) ] (ClusterIP: 10.96.120.45, Port: 80)
          │
          │ selector: app=backend
          ▼
[ ENDPOINTS (backend-service) ]
  ├── 10.244.1.12:8080 (Pod 1)
  ├── 10.244.2.15:8080 (Pod 2)
  └── 10.244.1.18:8080 (Pod 3)
          │
          ▼ (Round-Robin Yük Dengeleme)
       [ POD'LAR ]
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-05
cd ~/labs/LAB-K8S-05
```

---

### Adım 2: Backend Uygulaması Deployment'ı Hazırlayın

Basit bir Node.js / Nginx backend servisi oluşturalım:

```bash
cat <<'EOF' > backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  labels:
    app: backend-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      containers:
        - name: web
          image: nginx:alpine
          ports:
            - containerPort: 80
EOF

kubectl apply -f backend-deployment.yaml
kubectl rollout status deployment/backend-app
```

---

### Adım 3: ClusterIP Servis Tanımlayın

```bash
cat <<'EOF' > backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend-api
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF

kubectl apply -f backend-service.yaml
```

---

### Adım 4: Servis ve Endpoint Eşleşmesini Doğrulayın

Servisin aldığı sanal ClusterIP adresini ve bu servise bağlı gerçek Pod IP adreslerini inceleyin:

```bash
kubectl get service backend-service
kubectl get endpoints backend-service
```

`ENDPOINTS` sütununda 3 adet Pod IP'sinin (`10.244.x.x:80`) virgülle ayrılmış olarak listelendiğini doğrulayın.

---

### Adım 5: Küme İçi DNS Çözümleme Testi

Küme içinde geçici bir test pod'u başlatarak servis adına HTTP isteği ve DNS sorgusu atın:

```bash
kubectl run test-client --rm -i --restart=Never --image=curlimages/curl -- sh -c '
  echo "--- 1. DNS SORGUSU ---"
  nslookup backend-service
  echo "--- 2. HTTP İSTEĞİ ---"
  curl -s -I http://backend-service
'
```

CoreDNS'in `backend-service.training.svc.cluster.local` adresini başarıyla çözdüğünü ve Nginx HTTP 200 yanıtının döndüğünü görün.

---

### Adım 6: Hatalı Selector Arıza Simülasyonu ve Teşhis

Şimdi servisteki selector etiketini bilerek bozalım:

```bash
kubectl set selector service backend-service app=yanlis-etiket
```

Endpoints nesnesini hemen inceleyin:

```bash
kubectl get endpoints backend-service
```

`ENDPOINTS: <none>` olduğunu göreceksiniz. Şimdi test pod'undan istek göndermeyi deneyin:

```bash
kubectl run test-client --rm -i --restart=Never --image=curlimages/curl -- curl --connect-timeout 2 http://backend-service || echo "BEKLENEN: Endpoint yok, bağlantı koptu!"
```

**Düzeltme:** Selector'ı tekrar `app=backend-api` olarak düzeltin:

```bash
kubectl set selector service backend-service app=backend-api
kubectl get endpoints backend-service
```

Endpoint'lerin anında geri geldiğini doğrulayın.

---

## Doğal Doğrulama

```bash
# Servisin aktif endpoint sayısının 3 olduğunu doğrulayın
EP_COUNT=$(kubectl get endpoints backend-service -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w)
[ "$EP_COUNT" -eq 3 ] && echo "DOĞRULAMA BAŞARILI: 3 Endpoint de servise bağlı."
```

---

### Adım 7: Temizlik

```bash
kubectl delete -f backend-service.yaml -f backend-deployment.yaml
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Bir servise istek atıldığında `Connection refused` veya zaman aşımı alınıyorsa ilk kontrol edilmesi gereken nesne nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `kubectl get endpoints <service_name>` komutudur. Eğer endpoints `<none>` görünüyorsa, Service manifestindeki `spec.selector` ile Pod'lardaki `metadata.labels` değerleri uyuşmuyor demektir.

??? question "Soru 2: `port` ile `targetPort` arasındaki fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `port`, diğer pod'ların Service ClusterIP'sine bağlanırken kullanacağı porttur (örneğin 80). `targetPort` ise isteğin iletileceği hedef Pod container'ının dinlediği gerçek porttur (örneğin 8080).

---

## Beklenen Sonuç

- `kubectl get endpoints backend-service` çıktısında 3 adet IP adresinin bulunması.
- `nslookup backend-service` çıktısında ClusterIP adresinin çözülmesi.
