# LAB-K8S-08 — PersistentVolume ve PersistentVolumeClaim

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 45 dakika | `kubernetes` | `Küme içi` |

[LAB-K8S-08.zip](/downloads/LAB-K8S-08.zip)

## Amaç

- Düğüm üzerindeki yerel yolu statik bir PersistentVolume (PV) olarak tanımlamak.
- PersistentVolumeClaim (PVC) oluşturup doğru StorageClass ile PV'ye bağlamak.
- Pod silinse bile aynı PVC üzerindeki dosyanın yeni Pod tarafından okunabildiğini kanıtlamak.

## Ön Koşullar

- LAB-K8S-01 ile oluşturulmuş çalışan bir kind kümesi.
- `kubectl` ve Docker CLI erişimi.

## PersistentVolume ve PVC Mimarisi

```text
[ PV: lab-k8s-08-local-pv ]
  hostPath: /tmp/lab-k8s-08
  StorageClass: lab-k8s-08-local
            │ statik eşleşme
            ▼
[ PVC: app-data ] ──► [ Pod: writer ] ──► /data/evidence.txt
                                      (Pod silinse de dosya kalır)
```

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-08
cd ~/labs/LAB-K8S-08
```

### Adım 2: Yerel statik PV'yi oluşturun

```bash
cat <<'EOF' > storage.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: lab-k8s-08
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: lab-k8s-08-local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: lab-k8s-08-local
  hostPath:
    path: /tmp/lab-k8s-08
    type: DirectoryOrCreate
EOF

kubectl apply -f storage.yaml
kubectl get pv lab-k8s-08-local-pv
```

PV'nin `Available` olduğunu ve `lab-k8s-08-local` sınıfını kullandığını görün.

### Adım 3: PV'ye bağlanan PVC'yi oluşturun

```bash
cat <<'EOF' > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: lab-k8s-08
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: lab-k8s-08-local
  resources:
    requests:
      storage: 1Gi
EOF

kubectl apply -f pvc.yaml
kubectl get pv lab-k8s-08-local-pv
kubectl get pvc app-data -n lab-k8s-08
```

PV ve PVC durumlarının `Bound` olduğunu görün. Bu, dinamik provisioner yerine statik PV-PVC eşleşmesidir.

### Adım 4: PVC bağlı Pod'u başlatın

```bash
cat <<'EOF' > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer
  namespace: lab-k8s-08
spec:
  containers:
    - name: writer
      image: busybox:1.36.1
      command: ["sh", "-c", "date -u > /data/evidence.txt; cat /data/evidence.txt; sleep 3600"]
      volumeMounts:
        - name: my-data
          mountPath: /data
  volumes:
    - name: my-data
      persistentVolumeClaim:
        claimName: app-data
EOF

kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/writer -n lab-k8s-08 --timeout=120s
kubectl exec -n lab-k8s-08 writer -- cat /data/evidence.txt
```

Pod'un `Running` olduğunu ve dosyanın tarih bilgisini içerdiğini görün.

### Adım 5: Pod'u silip kalıcılığı kanıtlayın

```bash
kubectl delete pod writer -n lab-k8s-08 --wait=true
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/writer -n lab-k8s-08 --timeout=120s
kubectl exec -n lab-k8s-08 writer -- test -s /data/evidence.txt
kubectl exec -n lab-k8s-08 writer -- cat /data/evidence.txt
```

Dosyanın yeni Pod'da da okunabildiğini görün; veri, statik PV'nin hostPath'inde korunmuştur.

## Doğal Doğrulama ve Beklenen Sonuç

```bash
kubectl get pv lab-k8s-08-local-pv
kubectl get pvc app-data -n lab-k8s-08
kubectl exec -n lab-k8s-08 writer -- test -s /data/evidence.txt
```

PV ve PVC `Bound` olmalı, son komut başarıyla dönmeli ve `evidence.txt` tarih satırını göstermelidir.
