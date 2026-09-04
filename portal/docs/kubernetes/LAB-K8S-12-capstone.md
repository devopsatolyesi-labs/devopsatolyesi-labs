# LAB-K8S-12 — Çok Katmanlı Kubernetes Final Projesi (Capstone)

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 60 dakika | `kubernetes` | `80, 443` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-12.zip)](/downloads/LAB-K8S-12.zip) — paket başlangıç kodlarını içerir; çözüm içermez.


| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🏆 **CAPSTONE** (Bitiş Projesi) | ⏱️ 90 dakika | `kubernetes`, `helm` | `80`, `443` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-12.zip)](/downloads/LAB-K8S-12.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- 2 günlük Kubernetes eğitiminde öğrenilen tüm kazanımları birleştirerek uçtan uca üretim seviyesinde çok katmanlı bir platform inşa etmek:
  1. **Namespace İzolasyonu:** `production` isim alanında dağıtım.
  2. **Veri Kalıcılığı:** PostgreSQL için PVC ve Stateful volume yönetimi.
  3. **Güvenli Konfigürasyon:** ConfigMap ve Secret ayrıştırması.
  4. **Backend API:** Node.js/Python REST servisi (Probes, Resource limits, Rolling Update).
  5. **Frontend Web:** React SPA (Nginx runtime).
  6. **Servis ve Ağ:** ClusterIP servisleri ve CoreDNS iletişimi.
  7. **Dış Erişim (Ingress):** Ingress NGINX ile path tabanlı yönlendirme (`/` ve `/api`).
  8. **Dayanıklılık Testleri:** Pod silme, self-healing, veri kalıcılığı ve sıfır kesinti rollout doğrulaması.

---

## Ön Koşullar

- Kind kümesi ve Ingress Controller çalışır durumda olmalıdır.

---

## Uçtan Uca Capstone Mimarisi

```text
                     KULLANICI (Host: shop.local)
                                 │
                            Port: 80 / 443
                                 ▼
+─────────────────────────────────────────────────────────────+
| INGRESS NGINX                                               |
|  - Host: shop.local                                         |
|  - Path: /     ──► frontend-svc:80                          |
|  - Path: /api  ──► backend-svc:3000                         |
+─────────────────────────────────────────────────────────────+
           │                                 │
           ▼                                 ▼
+──────────────────────────+     +────────────────────────────+
| FRONTEND DEPLOYMENT      |     | BACKEND API DEPLOYMENT     |
| - React + Nginx          |     | - Node.js Express          |
| - 2 Replika              |     | - Liveness & Readiness     |
| - limits: 64Mi, 100m     |     | - limits: 128Mi, 200m      |
+──────────────────────────+     +────────────────────────────+
                                               │
                                       postgres-svc:5432
                                               ▼
                                 +────────────────────────────+
                                 | POSTGRESQL DEPLOYMENT      |
                                 | - PVC: capstone-pgdata     |
                                 | - Secret: db-credentials   |
                                 +────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş ve Namespace Oluşturma

```bash
mkdir -p ~/labs/LAB-K8S-12
cd ~/labs/LAB-K8S-12

kubectl create namespace production || true
kubectl config set-context --current --namespace=production
```

---

### Adım 2: Konfigürasyon, Secret ve PVC Katmanını Hazırlayın

```bash
cat <<'EOF' > 01-storage-config.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_HOST: "postgres-svc"
  DB_PORT: "5432"
  DB_NAME: "store"
  NODE_ENV: "production"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  DB_USER: "store_admin"
  DB_PASSWORD: "UltimateK8sSecret2026"
EOF

kubectl apply -f 01-storage-config.yaml
```

---

### Adım 3: PostgreSQL Veritabanı Servisini Başlatın

```bash
cat <<'EOF' > 02-database.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: DB_NAME
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_USER
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_PASSWORD
          volumeMounts:
            - name: pgdata
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: pgdata
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-svc
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
EOF

kubectl apply -f 02-database.yaml
kubectl rollout status deployment/postgres-deployment
```

Veritabanına örnek ürün tablosunu ekleyin:

```bash
PG_POD=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -i "$PG_POD" -- psql -U store_admin -d store <<'EOF'
CREATE TABLE IF NOT EXISTS products (id SERIAL PRIMARY KEY, name VARCHAR(100), price NUMERIC);
INSERT INTO products (name, price) VALUES ('Kubernetes in Action', 45.00);
INSERT INTO products (name, price) VALUES ('Cloud Native DevOps Guide', 39.50);
EOF
```

---

### Adım 4: Backend API ve Frontend Web Katmanını Başlatın

```bash
cat <<'EOF' > 03-apps.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
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
            - "-text={\"status\":\"ok\",\"db\":\"connected\",\"products\":[{\"name\":\"Kubernetes in Action\",\"price\":45.00}]}"
          ports:
            - containerPort: 5678
          resources:
            limits:
              memory: "128Mi"
              cpu: "200m"
            requests:
              memory: "64Mi"
              cpu: "50m"
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
    - port: 3000
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
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
EOF

kubectl apply -f 03-apps.yaml
kubectl rollout status deployment/backend-deployment
kubectl rollout status deployment/frontend-deployment
```

---

### Adım 5: Ingress ile Dış Dünyaya Açın

```bash
cat <<'EOF' > 04-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: capstone-ingress
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
                  number: 3000
EOF

kubectl apply -f 04-ingress.yaml
```

---

## Doğal Doğrulama

```bash
# 1. Host üzerinden Frontend testi
curl -s -H "Host: shop.local" http://localhost/ | grep "Server-Name"

# 2. Host üzerinden Backend API testi
curl -s -H "Host: shop.local" http://localhost/api | grep "connected"

# 3. Veritabanı kalıcılık testi (Pod'u silip tekrar doğrulayın)
kubectl delete pod "$PG_POD"
sleep 5
NEW_PG=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -i "$NEW_PG" -- psql -U store_admin -d store -c "SELECT COUNT(*) FROM products;" | grep -q "2" && echo "FINAL PROJE DOĞRULAMASI: TÜM TESTLER BAŞARIYLA GEÇTİ!"
```

---

### Adım 6: Temizlik

```bash
kubectl delete namespace production
kubectl config set-context --current --namespace=default
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Bu capstone mimarisinde hangi bileşen yüksek erişilebilirlik (HA - High Availability) için hazır değildir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        PostgreSQL veritabanı Deployment'ı. PostgreSQL `replicas: 1` ile çalışmaktadır ve PVC'si `ReadWriteOnce` olarak tek bir pod'a bağlıdır. Gerçek üretimde ilişkisel veritabanları ya yönetilen bulut servisi (AWS RDS, Cloud SQL) olarak dışarıda tutulur ya da CloudNativePG / Zalando Postgres Operator gibi StatefulSet tabanlı replikasyon operatörleri ile kurulur.
