# LAB-K8S-04 — Scaling, Rolling Update ve Rollback

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `kubernetes`, `kubectl` | `80` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-04.zip)](/downloads/LAB-K8S-04.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Kubernetes Deployment'larında sıfır kesintili sürüm güncelleme (**Zero-Downtime Rolling Update**) sürecini yönetmek.
- `maxSurge` ve `maxUnavailable` parametrelerinin rollout hızına etkisini kavramak.
- Canlı yayına hatalı/bozuk bir imaj (`ImagePullBackOff`) sürerek dağıtımın kilitlenmesini simüle etmek.
- Dağıtım geçmişini incelemek (`kubectl rollout history`).
- Tek komutla önceki kararlı sürüme acil geri dönüş (**Rollback / `rollout undo`**) yapmak.

---

## Ön Koşullar

- Kind kümesi aktif olmalıdır.

---

## Rolling Update ve Rollback Mekanizması

```text
SÜRÜM V1 (nginx:1.24)                SÜRÜM V2 (HATALI: nginx:9.99)
ReplicaSet-v1 (3 Pod)                 ReplicaSet-v2 (1 Pod -> ImagePullBackOff)
[ Pod v1 ] [ Pod v1 ] [ Pod v1 ]      [ Pod v2 (HATA!) ]
        │                                     │
        │                                     ▼ (DAĞITIM DURDU)
        │                            kubectl rollout undo
        ◄─────────────────────────────────────┘ (Rollback yapıldı)
Sistem kesintisiz olarak V1 sürümünde çalışmaya devam eder!
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-04
cd ~/labs/LAB-K8S-04
```

---

### Adım 2: Rolling Update Stratejili Deployment Hazırlayın

```bash
cat <<'EOF' > rollout-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rollout-app
  annotations:
    kubernetes.io/change-cause: "v1: Initial release with nginx 1.25"
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Güncelleme sırasında en fazla 1 ekstra pod açılabilir
      maxUnavailable: 0  # Güncelleme anında hiçbir pod eksilmez (Kesintisiz)
  selector:
    matchLabels:
      app: rollout-demo
  template:
    metadata:
      labels:
        app: rollout-demo
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
EOF

kubectl apply -f rollout-app.yaml
kubectl rollout status deployment/rollout-app
```

---

### Adım 3: Sürüm 2'ye Güncelleme Yapın (Rolling Update)

İmajı `nginx:1.26-alpine` sürümüne güncelleyin ve açıklama ekleyin:

```bash
kubectl set image deployment/rollout-app web=nginx:1.26-alpine
kubectl annotate deployment/rollout-app kubernetes.io/change-cause="v2: Upgraded to nginx 1.26" --overwrite
```

Güncelleme sürecini anlık olarak izleyin:

```bash
kubectl rollout status deployment/rollout-app
```

İmajın başarıyla güncellendiğini doğrulayın:

```bash
kubectl get pods -l app=rollout-demo -o jsonpath="{.items[*].spec.containers[*].image}"
```

---

### Adım 4: Bilerek Hatalı Sürüm Dağıtımı Simülasyonu

Var olmayan bir imaj etiketi vererek dağıtımı bozalım:

```bash
kubectl set image deployment/rollout-app web=nginx:surum-yok-999
kubectl annotate deployment/rollout-app kubernetes.io/change-cause="v3: Broken image deployment" --overwrite
```

Durumu izleyin:

```bash
kubectl get pods -l app=rollout-demo
```

Yeni Pod'un `ImagePullBackOff` veya `ErrImagePull` hatasına düştüğünü; ancak `maxUnavailable: 0` kuralımız sayesinde çalışan 4 adet v2 pod'unun **kesintisiz hizmet vermeye devam ettiğini** görün!

---

### Adım 5: Dağıtım Geçmişini İnceleyin ve Acil Rollback Yapın

```bash
kubectl rollout history deployment/rollout-app
```

Sistemi v2 kararlı sürümüne anında geri döndürün:

```bash
kubectl rollout undo deployment/rollout-app
```

Rollback durumunu doğrulayın:

```bash
kubectl rollout status deployment/rollout-app
kubectl get pods -l app=rollout-demo
```

Hatalı pod'un anında yok edildiğini ve sistemin tamamen sağlıklı olduğunu görün!

---

## Doğal Doğrulama

Konteynerlerin sağlıklı `nginx:1.26-alpine` imajına geri döndüğünü CLI ile teyit edin:

```bash
IMAGE=$(kubectl get deployment rollout-app -o jsonpath='{.spec.template.spec.containers[0].image}')
[ "$IMAGE" = "nginx:1.26-alpine" ] && echo "DOĞRULAMA BAŞARILI: Hatalı sürümden güvenle rollback yapıldı!"
```

---

### Adım 6: Temizlik

```bash
kubectl delete -f rollout-app.yaml
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: `maxUnavailable: 0` ve `maxSurge: 1` parametreleri production ortamında ne sağlar?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        **Sıfır Kesinti (Zero Downtime).** `maxUnavailable: 0`, yeni sürüm pod sağlıklı olup trafiği karşılamaya başlamadan önce eski pod'ların asla kapatılmayacağını garanti eder. `maxSurge: 1` ise kümede geçici olarak en fazla 1 ilave pod için kaynak tüketileceğini belirler.

??? question "Soru 2: Belirli bir geçmiş revizyona (örneğin 1. revizyona) doğrudan nasıl dönebiliriz?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `kubectl rollout undo deployment/rollout-app --to-revision=1` komutu kullanılarak istenen spesifik revizyona dönülebilir.

---

## Beklenen Sonuç

- `rollout undo` sonrası tüm pod'ların `Running` durumunda olması.
- `kubectl rollout history` çıktısında revizyon kayıtlarının görülmesi.
