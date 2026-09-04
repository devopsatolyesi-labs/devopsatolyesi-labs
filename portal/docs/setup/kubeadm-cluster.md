# Kubeadm ile Multi-Node Kubernetes Kümesi Kurulumu

Bu rehber, **Ubuntu 22.04 / 24.04 LTS** sunucular üzerinde `kubeadm`, `containerd` ve `Calico CNI` kullanarak üretim standartlarında **1 Control-Plane (Master)** ve **2 Worker** düğümlü Kubernetes kümesi kurulumunu adım adım açıklar.

---

## 1. Tüm Düğümlerde Ortak Hazırlıklar (Master + Workers)

Aşağıdaki komutları **hem Master hem de tüm Worker** sunucularında çalıştırın:

### Adım 1: Swap Alanını Devre Dışı Bırakın
Kubernetes kubelet bileşeni varsayılan olarak swap alanının kapalı olmasını gerektirir:

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### Adım 2: Gerekli Kernel Modüllerini ve Sysctl Parametrelerini Yükleyin

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Ağ filtreleme ve IP forwarding ayarları
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### Adım 3: Container Runtime (Containerd) Kurulumu ve Yapılandırması

```bash
sudo apt-get update
sudo apt-get install -y containerd

# Containerd varsayılan yapılandırmasını üretin ve SystemdCgroup özelliğini aktif edin
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Containerd servisini yeniden başlatın
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Adım 4: Kubeadm, Kubelet ve Kubectl Paketlerinin Kurulumu

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Kubernetes resmi APT anahtarı (v1.30)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 2. Control-Plane (Master Düğüm) Başlatma

Bu adımı **yalnızca Master sunucuda** çalıştırın:

```bash
MASTER_IP=$(hostname -I | awk '{print $1}')

sudo kubeadm init   --apiserver-advertise-address="$MASTER_IP"   --pod-network-cidr=192.168.0.0/16   --cri-socket=unix:///var/run/containerd/containerd.sock
```

### Kubeconfig Yetkilerini Ayarlayın:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Calico CNI (Pod Ağ Eklentisi) Kurulumu:

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
```

---

## 3. Worker Düğümleri Kümeye Dahil Etme (Join)

Master düğümde üretilen `kubeadm join` komutunu alıp **Worker düğümlerde** çalıştırın:

```bash
# Master üzerinde join komutunu yeniden üretmek isterseniz:
kubeadm token create --print-join-command
```

Worker düğümde komutu `sudo` ile çalıştırın:
```bash
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

---

## 4. Küme Durumunu Doğrulama

Master sunucuda:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

Tüm düğümler `Ready` ve Calico / CoreDNS podları `Running` olmalıdır.
