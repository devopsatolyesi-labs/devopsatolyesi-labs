# Dynamic NFS Provisioning & StorageClass Kurulumu

> Kaynak: [How to Set Up Dynamic NFS Provisioning in Kubernetes — Hakan Bayraktar](https://hbayraktar.medium.com/how-to-set-up-dynamic-nfs-provisioning-in-kubernetes-0fa225d36e2f)

Kubernetes kümelerinde StatefulSet ler, veritabanları veya paylaşılan depolama (ReadWriteMany - RWX) gereksinimleri için **Dynamic NFS Provisioner** kurarak otomatik PersistentVolume oluşturan bir **StorageClass** tanımlayabilirsiniz.

---

## 1. NFS Sunucusu Hazırlığı (NFS Server)

NFS sunucusu olarak kullanılacak makinede:

```bash
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

# Paylaşılacak dizini oluşturun
sudo mkdir -p /srv/nfs/kubedata
sudo chown -R nobody:nogroup /srv/nfs/kubedata
sudo chmod 777 /srv/nfs/kubedata

# /etc/exports dosyasına ekleyin
echo "/srv/nfs/kubedata *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

sudo exportfs -rav
sudo systemctl restart nfs-kernel-server
```

---

## 2. Tüm Kubernetes Düğümlerinde NFS İstemcisini Kurun

Tüm worker düğümlerin NFS paylaşımına erişebilmesi için:

```bash
sudo apt-get install -y nfs-common
```

---

## 3. Helm ile NFS Subdir External Provisioner Kurulumu

```bash
# Helm deposunu ekleyin
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

# NFS sunucu IP sini ve dizinini belirterek kurun
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner   --namespace nfs-provisioner --create-namespace   --set nfs.server=192.168.1.50   --set nfs.path=/srv/nfs/kubedata   --set storageClass.name=nfs-client   --set storageClass.defaultClass=true
```

---

## 4. Test PVC ve Pod ile Dinamik Provisioning Doğrulama

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: test-nfs-pod
spec:
  containers:
    - name: test-app
      image: busybox
      command: ["sh", "-c", "while true; do echo $(date) >> /mnt/data/test.log; sleep 5; done"]
      volumeMounts:
        - name: nfs-vol
          mountPath: /mnt/data
  volumes:
    - name: nfs-vol
      persistentVolumeClaim:
        claimName: test-nfs-pvc
EOF
```

Doğrulama:
```bash
kubectl get pvc test-nfs-pvc # Status: Bound olmalıdır
kubectl get pv               # Dinamik oluşturulan PV listelenir
```

Temizlik:
```bash
kubectl delete pod test-nfs-pod
kubectl delete pvc test-nfs-pvc
```
