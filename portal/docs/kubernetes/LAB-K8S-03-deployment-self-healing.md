# LAB-K8S-03 — Deployment, ReplicaSet ve Self-Healing

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 45 dakika | `kubernetes` | `Küme içi` |

[LAB-K8S-03.zip](/downloads/LAB-K8S-03.zip)


---

## Amaç

- **Deployment**, **ReplicaSet** ve **Pod** arasındaki 3 katmanlı hiyerarşik ilişkiyi kavramak.
- 3 replikalı bildirimsel bir Deployment manifesti hazırlamak ve kümeye uygulamak.
- Kendi kendini onarma (**Self-Healing**) mekanizmasını canlı olarak test etmek (Bir Pod silindiğinde saniyeler içinde yenisinin yaratılması).
- Label Selector (`matchLabels`) ve Pod şablonu (`template.metadata.labels`) eşleşmesini doğrulamak.
- `kubectl scale` komutu ile yatay ölçekleme (horizontal scaling) dinamiklerini gözlemlemek.

---

## Ön Koşullar

- Kind kümesi aktif olmalıdır.

---

## Deployment ve Self-Healing Mimarisi

```text
[ DEPLOYMENT (web-deployment) ]
  - İstenen Durum: replicas: 3
  - Strateji: RollingUpdate
          │
          │ Yönetir
          ▼
[ REPLICASET (web-deployment-7bf48...) ]
  - Aktif Pod sayısını sürekli 3'te tutar
          │
          ├───► [ POD 1 ] (Worker 1)
          ├───► [ POD 2 ] (Worker 2)
          └───► [ POD 3 ] (Worker 1)  <--- kubectl delete pod
                                                 │
                                                 ▼ (Anında Yenisi Oluşur!)
                                        [ POD 4 ] (Worker 2)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-03
cd ~/labs/LAB-K8S-03
```

---

### Adım 2: 3 Replikalı Deployment Manifesti Hazırlayın

```bash
cat <<'EOF' > web-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: order-web
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-web
  template:
    metadata:
      labels:
        app: order-web
    spec:
      containers:
        - name: web-app
          image: nginx:alpine
          ports:
            - containerPort: 80
          resources:
            limits:
              memory: "128Mi"
              cpu: "200m"
            requests:
              memory: "64Mi"
              cpu: "50m"
EOF
```

---

### Adım 3: Deployment'ı Kümeye Uygulayın

```bash
kubectl apply -f web-deployment.yaml
```

Hiyerarşiyi tek bir komutla sorgulayın:

```bash
kubectl get deployment,replicaset,pods -l app=order-web
```

1 adet Deployment, 1 adet ReplicaSet ve 3 adet Pod'un `Running` durumda olduğunu görün.

---

### Adım 4: Canlı Self-Healing (Kendi Kendini Onarma) Testi

Pod'ların gerçek zamanlı durumunu izlemek için arka planda bir watcher açın:

```bash
# İlk Pod'un adını değişkene alın
TARGET_POD=$(kubectl get pods -l app=order-web -o jsonpath='{.items[0].metadata.name}')
echo "Hedef Pod: $TARGET_POD"

# Bu Pod'u kasten silin
kubectl delete pod "$TARGET_POD"
```

Hemen pod listesini tekrar çekin:

```bash
kubectl get pods -l app=order-web
```

Eski Pod `Terminating` durumuna geçerken, ReplicaSet'in anında yeni bir isimle 3. Pod'u yarattığını ve toplam sayının daima 3 kaldığını görün!

---

### Adım 5: Dinamik Yatay Ölçekleme (Scaling)

Replika sayısını 3'ten 5'e çıkarın:

```bash
kubectl scale deployment web-deployment --replicas=5
kubectl rollout status deployment/web-deployment
```

Yeni Pod'ların cluster worker düğümlerine nasıl dağıtıldığını inceleyin:

```bash
kubectl get pods -o wide -l app=order-web
```

Şimdi tekrar 2 replikaya düşürün:

```bash
kubectl scale deployment web-deployment --replicas=2
kubectl get pods -l app=order-web
```

Fazlalık pod'ların zarifçe (gracefully) sonlandırıldığını gözlemleyin.

---

## Doğal Doğrulama

```bash
# Aktif pod sayısının tam olarak 2 olduğunu doğrulayın
READY_COUNT=$(kubectl get deployment web-deployment -o jsonpath='{.status.readyReplicas}')
[ "$READY_COUNT" -eq 2 ] && echo "DOĞRULAMA BAŞARILI: Deployment 2 replika ile kusursuz çalışıyor."
```

---

## Doğal Doğrulama ve Beklenen Sonuç

- `kubectl get deployment` çıktısında `UP-TO-DATE` ve `AVAILABLE` değerlerinin replika sayısıyla eşit olması.
- Silinen pod'un yerine anında yeni bir pod'un yaratılması.
