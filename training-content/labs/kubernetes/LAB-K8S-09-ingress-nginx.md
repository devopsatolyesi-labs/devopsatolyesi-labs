# LAB-K8S-09 — Ingress NGINX ile Uygulama Yayınlama

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `kubernetes`, `ingress` | `80`, `443` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-09.zip)](/downloads/LAB-K8S-09.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Kubernetes **Ingress** kavramını ve Katman 7 (L7) HTTP/HTTPS yönlendirme mantığını anlamak.
- Kind kümesine resmi **Ingress NGINX Controller** bileşenini kurmak.
- Host tabanlı (`app.local`) ve yol tabanlı (Path-based: `/` frontend, `/api` backend) yönlendirme kuralları tanımlamak.
- Ingress, Service ve Pod arasındaki uçtan uca ağ akışını doğrulamak.
- Yanlış service port yapılandırmasından kaynaklanan 502/503 yönlendirme hatalarını teşhis etmek.

---

## Ön Koşullar

- Kind kümesi `extraPortMappings` (80 ve 443 portları) ile oluşturulmuş olmalıdır (`LAB-K8S-01`).

---

## Ingress Yönlendirme Mimarisi

```text
               İSTEMCİ (Tarayıcı / curl)
                         │
                    Host: 80 / 443
                         ▼
+─────────────────────────────────────────────────────────────+
| INGRESS NGINX CONTROLLER                                    |
|                                                             |
|  Kural: Host "shop.local"                                   |
|   ├── Path "/"     ──► frontend-svc:80  ──► [ Frontend Pods]|
|   └── Path "/api"  ──► backend-svc:80   ──► [ Backend Pods ]|
+─────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-09
cd ~/labs/LAB-K8S-09
```

---

### Adım 2: Kind Uyumlu Ingress NGINX Controller Kurulumu

Kind için hazırlanmış resmi Nginx Ingress manifestini uygulayın:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Ingress Controller pod'unun hazır (`Running`) olmasını bekleyin:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

---

### Adım 3: Frontend ve Backend Örnek Servislerini Başlatın

```bash
cat <<'EOF' > app-stack.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-dep
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: web
          image: nginxdemos/hello:plain-text
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-dep
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: api
          image: hashicorp/http-echo:latest
          args:
            - "-text={\"service\":\"Product Catalog API\",\"version\":\"1.0.0\"}"
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl apply -f app-stack.yaml
```

---

### Adım 4: Path ve Host Tabanlı Ingress Kaynağı Tanımlayın

```bash
cat <<'EOF' > ingress-rules.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: shop.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-svc
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-svc
                port:
                  number: 80
EOF

kubectl apply -f ingress-rules.yaml
```

---

## Doğal Doğrulama

Host üzerinden `shop.local` Host başlığı ile istek atarak yönlendirmeyi test edin:

```bash
# 1. Ana sayfayı sorgulayın (Frontend Nginx yanıtı dönmelidir)
curl -s -H "Host: shop.local" http://localhost/ | grep "Server-Name"

# 2. /api yolunu sorgulayın (Backend JSON yanıtı dönmelidir)
curl -s -H "Host: shop.local" http://localhost/api
```

`/api` yoluna atılan isteğin `Product Catalog API` çıktısı verdiğini doğrulayın.

---

### Adım 5: Temizlik

```bash
kubectl delete -f ingress-rules.yaml -f app-stack.yaml
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Neden her mikroservis için ayrı bir `NodePort` açmak yerine `Ingress` tercih edilir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `NodePort` kullanıldığında her servis için 30000-32767 aralığında garip bir port açılır ve dış firewall kuralları karmaşıklaşır. `Ingress` ise tek bir 80/443 IP adresini paylaşır; SSL sonlandırma (TLS Termination), alan adı tabanlı yönlendirme (`api.sirket.com`, `app.sirket.com`) ve yol tabanlı yönlendirmeyi tek bir noktadan yönetir.

---

## Beklenen Sonuç

- `curl -s -H "Host: shop.local" http://localhost/api` çıktısında `{"service":"Product Catalog API","version":"1.0.0"}` JSON metninin alınması.
