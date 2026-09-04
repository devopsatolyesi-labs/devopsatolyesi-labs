# LAB-K8S-11 — Kubernetes Troubleshooting Challenge

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🔴 **ADVANCED** (İleri Seviye) | ⏱️ 60 dakika | `kubernetes`, `kubectl` | `8080`, `5432` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-11.zip)](/downloads/LAB-K8S-11.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Üretim ortamlarında en sık rastlanan 5 kritik Kubernetes arızasını teşhis etmek ve onarmak:
  1. `ImagePullBackOff` — Yanlış imaj adı veya registry erişim hatası.
  2. `CrashLoopBackOff` — Yanlış başlangıç komutu veya eksik bağımlılık.
  3. `CreateContainerConfigError` — Tanımlanmamış veya eksik Secret/ConfigMap referansı.
  4. `Pending` — Düğümlerin karşılayamayacağı aşırı CPU/RAM istekleri.
  5. `Endpoint Yokluğu` — Service selector ve Pod label uyuşmazlığı.
- Standart arıza teşhis metodolojisini (`get`, `describe`, `logs`, `events`) refleks haline getirmek.

---

## Ön Koşullar

- Kind kümesi aktif olmalıdır.

---

## Kubernetes Hata Teşhis Akış Şeması

```text
[ POD ÇALIŞMIYOR ]
        │
        ├── STATUS: ImagePullBackOff? ──► kubectl describe pod (Events'te imaj adı kontrolü)
        │
        ├── STATUS: CrashLoopBackOff? ──► kubectl logs <pod> --previous (Çökme nedeni logu)
        │
        ├── STATUS: Pending?          ──► kubectl describe pod (Insufficient cpu/memory kontrolü)
        │
        └── STATUS: Running ama Trafik Yok?
                                      ──► kubectl get endpoints (Selector eşleşme kontrolü)
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-11
cd ~/labs/LAB-K8S-11
```

---

### Adım 2: Arızalı Manifestleri Kümeye Yükleyin

Bozuk senaryoları tek bir dosyada uygulayalım:

```bash
cat <<'EOF' > broken-workloads.yaml
# Arıza 1: ImagePullBackOff
apiVersion: v1
kind: Pod
metadata:
  name: broken-image-pod
spec:
  containers:
    - name: app
      image: nginx:non-existent-tag-999
---
# Arıza 2: CrashLoopBackOff
apiVersion: v1
kind: Pod
metadata:
  name: crashloop-pod
spec:
  containers:
    - name: app
      image: alpine:3.19
      command: ["sh", "-c", "echo 'Starting...' && exit 1"]
---
# Arıza 3: CreateContainerConfigError
apiVersion: v1
kind: Pod
metadata:
  name: missing-secret-pod
spec:
  containers:
    - name: app
      image: alpine:3.19
      command: ["sleep", "3600"]
      env:
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: non-existent-secret
              key: password
---
# Arıza 4: Pending Pod
apiVersion: v1
kind: Pod
metadata:
  name: pending-pod
spec:
  containers:
    - name: heavy-app
      image: nginx:alpine
      resources:
        requests:
          cpu: "99" # Düğümde 99 çekirdek yok!
EOF

kubectl apply -f broken-workloads.yaml
```

---

### Adım 3: Arızaları Teşhis Edin ve Onarın

Pod listesini inceleyin:

```bash
kubectl get pods
```

#### Görev 1: `broken-image-pod` Onarımı
1. Hata tespiti:
   ```bash
   kubectl describe pod broken-image-pod | grep -A 3 Events
   ```
2. Onarım: Pod'u silin ve geçerli `nginx:alpine` imajıyla yeniden oluşturun:
   ```bash
   kubectl delete pod broken-image-pod
   kubectl run broken-image-pod --image=nginx:alpine
   ```

#### Görev 2: `crashloop-pod` Onarımı
1. Hata tespiti:
   ```bash
   kubectl logs crashloop-pod
   ```
   Konteynerin `exit 1` ile kapandığını görün.
2. Onarım:
   ```bash
   kubectl delete pod crashloop-pod
   kubectl run crashloop-pod --image=alpine:3.19 -- sh -c 'echo "Running fine" && sleep 3600'
   ```

#### Görev 3: `missing-secret-pod` Onarımı
1. Hata tespiti:
   ```bash
   kubectl describe pod missing-secret-pod | grep "secret \"non-existent-secret\" not found"
   ```
2. Onarım: Eksik olan secret nesnesini oluşturun:
   ```bash
   kubectl create secret generic non-existent-secret --from-literal=password=SecretKey123
   ```
   Pod'un birkaç saniye sonra otomatik olarak `Running` durumuna geçtiğini gözlemleyin!

#### Görev 4: `pending-pod` Onarımı
1. Hata tespiti:
   ```bash
   kubectl describe pod pending-pod | grep "0/3 nodes are available: 3 Insufficient cpu"
   ```
2. Onarım:
   ```bash
   kubectl delete pod pending-pod
   kubectl run pending-pod --image=nginx:alpine
   ```

---

## Doğal Doğrulama

Tüm pod'ların başarıyla `Running` durumuna ulaştığını doğrulayın:

```bash
NON_RUNNING=$(kubectl get pods --no-headers | grep -v "Running" | wc -l | tr -d ' ')
[ "$NON_RUNNING" -eq 0 ] && echo "TEBRİKLER: Tüm kritik Kubernetes arızaları başarıyla giderildi!"
```

---

### Adım 4: Temizlik

```bash
kubectl delete pod broken-image-pod crashloop-pod missing-secret-pod pending-pod
kubectl delete secret non-existent-secret
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Çöken ve yeniden başlayan bir konteynerin önceki çökme anındaki loglarına nasıl ulaşırız?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `kubectl logs <pod_name> --previous` komutu ile bir önceki konteyner örneğinin (instance) çökmeden hemen önce stdout/stderr'e yazdığı loglar okunabilir.
