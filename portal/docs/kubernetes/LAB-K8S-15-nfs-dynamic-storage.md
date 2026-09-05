# LAB-K8S-15 — NFS Dynamic Provisioning ve ReadWriteMany Depolama

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| İleri | 55 dakika | `kubernetes, helm` | `2049` |

[LAB-K8S-15.zip](/downloads/LAB-K8S-15.zip)


55 dakika | `kubernetes, helm` | `2049` |

## Amaç

- Ubuntu lab sunucusunda Kind ağıyla sınırlandırılmış bir NFS export oluşturmak
- NFS Subdir External Provisioner ile dinamik StorageClass kurmak
- `ReadWriteMany` PVC’yi birden fazla Pod’dan kullanmak
- Workload yeniden oluşturulduğunda ortak verinin kaldığını doğrulamak

## Ön Koşullar

- Ubuntu üzerinde çalışan bir kind kümesi
- `kubectl`, `helm`, `docker` ve `sudo` erişimi
- Host üzerinde TCP 2049 portunun başka bir NFS export ile çakışmaması

```bash
kubectl cluster-info
kind get nodes
docker network inspect kind
```

## Mimari ve Çalışma Modeli

```text
writer-1 Pod ─┐
              ├─ RWX PVC ── lab-nfs StorageClass ── provisioner ── NFS export
writer-2 Pod ─┘                                           /srv/nfs/lab-k8s-15
```

NFS server bu labda Kind Docker ağından erişilir. Export internete veya bütün yerel ağa açılmaz; `root_squash` etkin kalır.

## Adım Adım Uygulama Rehberi

### 1. NFS sunucusunu hazırlayın

```bash
sudo apt-get update
sudo apt-get install -y nfs-kernel-server nfs-common

export KIND_SUBNET="$(docker network inspect kind --format '{{(index .IPAM.Config 0).Subnet}}')"
export NFS_SERVER="$(docker network inspect kind --format '{{(index .IPAM.Config 0).Gateway}}')"

sudo install -d -o 65534 -g 65534 -m 0770 /srv/nfs/lab-k8s-15
printf '/srv/nfs/lab-k8s-15 %s(rw,sync,no_subtree_check,root_squash)\n' "$KIND_SUBNET" \
  | sudo tee /etc/exports.d/lab-k8s-15.exports
sudo exportfs -ra
sudo exportfs -v | grep /srv/nfs/lab-k8s-15
```

Kind node’larında NFS istemci aracını kurun:

```bash
for node in $(kind get nodes); do
  docker exec "$node" sh -c 'apt-get update && apt-get install -y nfs-common'
done
```

### 2. NFS provisioner ve StorageClass kurun

```bash
helm repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm upgrade --install lab-nfs \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace lab-k8s-15-system \
  --create-namespace \
  --set nfs.server="$NFS_SERVER" \
  --set nfs.path=/srv/nfs/lab-k8s-15 \
  --set storageClass.name=lab-nfs \
  --set storageClass.defaultClass=false \
  --set storageClass.onDelete=retain \
  --set-string nfs.defaultMode=0770 \
  --set-string nfs.defaultUid=65534 \
  --set-string nfs.defaultGid=65534 \
  --wait \
  --timeout 5m

kubectl get pods -n lab-k8s-15-system
kubectl get storageclass lab-nfs
```

### 3. RWX claim ve iki writer Pod oluşturun

```bash
mkdir -p lab-k8s-15
cd lab-k8s-15

cat <<'EOF' > workload.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: lab-k8s-15
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
  namespace: lab-k8s-15
spec:
  accessModes: [ReadWriteMany]
  storageClassName: lab-nfs
  resources:
    requests:
      storage: 256Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: writers
  namespace: lab-k8s-15
spec:
  replicas: 2
  selector:
    matchLabels:
      app: writers
  template:
    metadata:
      labels:
        app: writers
    spec:
      securityContext:
        runAsUser: 65534
        runAsGroup: 65534
        fsGroup: 65534
      containers:
        - name: writer
          image: busybox:1.36.1
          command: ["sh", "-c", "while true; do echo $(hostname) >> /shared/writers.txt; sleep 5; done"]
          volumeMounts:
            - name: shared
              mountPath: /shared
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared-data
EOF

kubectl apply -f workload.yaml
kubectl rollout status deployment/writers -n lab-k8s-15 --timeout=180s
kubectl get pvc,pv -n lab-k8s-15
```

### 4. Çoklu yazma ve kalıcılığı doğrulayın

```bash
sleep 12
export WRITER_POD="$(kubectl get pod -n lab-k8s-15 -l app=writers -o jsonpath='{.items[0].metadata.name}')"
kubectl exec -n lab-k8s-15 "$WRITER_POD" -- sort -u /shared/writers.txt
```

Çıktıda iki farklı Pod adı bulunmalıdır. Ardından Deployment’ı yeniden oluşturun:

```bash
kubectl delete deployment writers -n lab-k8s-15
kubectl apply -f workload.yaml
kubectl rollout status deployment/writers -n lab-k8s-15 --timeout=180s
export NEW_POD="$(kubectl get pod -n lab-k8s-15 -l app=writers -o jsonpath='{.items[0].metadata.name}')"
kubectl exec -n lab-k8s-15 "$NEW_POD" -- test -s /shared/writers.txt
```

## Doğal Doğrulama ve Beklenen Sonuç

```bash
kubectl get storageclass lab-nfs
kubectl get pvc shared-data -n lab-k8s-15 \
  -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,MODE:.status.accessModes[*],VOLUME:.spec.volumeName
kubectl exec -n lab-k8s-15 "$NEW_POD" -- sort -u /shared/writers.txt
sudo find /srv/nfs/lab-k8s-15 -name writers.txt -type f -size +0c
```

PVC `Bound` ve erişim modu `RWX` olmalı; ortak dosya birden fazla Pod kimliği içermeli ve NFS sunucusunda bulunmalıdır.
