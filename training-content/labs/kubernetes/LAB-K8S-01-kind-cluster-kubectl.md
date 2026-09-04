# LAB-K8S-01 — Kind ile Kubernetes Cluster Kurulumu ve kubectl

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 30 dakika | `kubernetes`, `kind` | `80`, `443` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-K8S-01.zip)](/downloads/LAB-K8S-01.zip) — paket başlangıç kodlarını içerir; çözüm içermez.

---

## Amaç

- Kind (Kubernetes in Docker) kullanarak yerel, çok düğümlü (multi-node) bir Kubernetes kümesi kurmak.
- Ingress controller ve dış trafik erişimi için host port eşlemelerini (port mappings) yapılandırmak.
- `kubectl` istemcisi ile API Server iletişimini, context ve cluster-info komutlarını doğrulamak.
- Node durumlarını (`Ready`), rollerini (`control-plane`, `worker`) ve sistem Pod'larını (`kube-system`) incelemek.
- Namespace kavramını ve aktif context/namespace değiştirme mekanizmasını kavramak.

---

## Ön Koşullar

- Docker Engine 24.0+ çalışır durumda olmalıdır.
- `kind` ve `kubectl` CLI araçları kurulu olmalıdır. Hızlı kontrol:
  ```bash
  docker --version
  kind --version
  kubectl version --client
  ```

---

## Kind Multi-Node Küme Mimarisi

```text
+-----------------------------------------------------------------------+
| ANA MAKİNE (HOST)                                                    |
|                                                                       |
|   kubectl CLI                                                         |
|        │                                                              |
|        ▼ (Port 6443)                                                  |
|   +---------------------------------------------------------------+   |
|   | CONTROL-PLANE NODE CONTAINER (kind-control-plane)             |   |
|   |   - kube-apiserver, etcd, controller-manager, scheduler       |   |
|   |   - Port 80 & 443 Host Bağlantısı (Ingress Ready)             |   |
|   +---------------------------------------------------------------+   |
|        │                                                              |
|        ├──────────────────────────────┐                               |
|        ▼                              ▼                               |
|   +--------------------------+   +--------------------------+         |
|   | WORKER 1 (kind-worker)   |   | WORKER 2 (kind-worker2)  |         |
|   |   - kubelet, kube-proxy  |   |   - kubelet, kube-proxy  |         |
|   |   - containerd           |   |   - containerd           |         |
|   +--------------------------+   +--------------------------+         |
+-----------------------------------------------------------------------+
```

---

## Adım Adım Uygulama Rehberi

### Adım 1: Çalışma Dizinine Geçiş

```bash
mkdir -p ~/labs/LAB-K8S-01
cd ~/labs/LAB-K8S-01
```

---

### Adım 2: Çok Düğümlü Kind Yapılandırmasını Hazırlayın

1 adet Control-Plane ve 2 adet Worker node içeren, ilerleyen lablarda Ingress NGINX trafiğini karşılayacak port eşlemeli `kind-config.yaml` dosyasını oluşturun:

```bash
cat <<'EOF' > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: devops-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
EOF
```

---

### Adım 3: Kubernetes Kümesini Başlatın

```bash
kind create cluster --config kind-config.yaml
```

Kind'ın node imajını çekmesini, control-plane bileşenlerini başlatmasını ve kubeconfig dosyasını otomatik ayarlamasını bekleyin.

---

### Adım 4: Küme Bağlantısını ve Düğümleri İnceleyin

```bash
# Küme kontrol düzlemi bilgilerini sorgulayın
kubectl cluster-info

# Düğümleri ve IP adreslerini genişletilmiş formatta listeleyin
kubectl get nodes -o wide
```

Tüm düğümlerin `STATUS: Ready` durumunda olduğunu ve 1 adet `control-plane` ile 2 adet `<none>` (worker) rolü bulunduğunu doğrulayın.

---

### Adım 5: Sistem Pod'larını ve Çekirdek Bileşenleri İnceleyin

Kubernetes'in kendi iç süreçlerinin çalıştığı `kube-system` isim alanındaki Pod'ları listeleyin:

```bash
kubectl get pods -n kube-system -o wide
```

`coredns`, `etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-proxy` ve `kube-scheduler` pod'larının çalıştığını (`Running`) görün.

---

### Adım 6: Context ve Namespace Yönetimi

Kubeconfig içerisindeki aktif context bilgisini sorgulayın:

```bash
kubectl config get-contexts
kubectl config current-context
```

Eğitim çalışmalarımız için izole bir namespace oluşturun:

```bash
kubectl create namespace training
kubectl get namespaces
```

Varsayılan çalışma alanını `training` olarak ayarlayın:

```bash
kubectl config set-context --current --namespace=training
```

Artık çalıştıracağınız tüm `kubectl` komutları otomatik olarak `training` namespace'ini hedefleyecektir.

---

## Doğal Doğrulama

```bash
# 1. 3 node'un da hazır olduğunu teyit edin
kubectl get nodes --no-headers | wc -l | grep -q "3" && echo "3 Node Başarıyla AYAKTA"

# 2. Aktif namespace'in training olduğunu doğrulayın
kubectl config view --minify --output 'jsonpath={..namespace}' | grep -q "training" && echo "Namespace: training AKTİF"
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Kind kümesinde `extraPortMappings` kullanmanın amacı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Kind node'ları aslında host üzerinde çalışan bağımsız Docker container'larıdır. Host makinenin `80` ve `443` portlarına gelen HTTP/HTTPS isteklerini doğrudan control-plane node konteynerine iletmek ve Ingress Controller üzerinden mikroservislere ulaştırmak için bu port yönlendirmesi tanımlanır.

??? question "Soru 2: `kubectl cluster-info` komutunda API Server adresi olarak neden `127.0.0.1:<rastgele-port>` görünür?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Kind, control-plane container'ının içindeki `6443` API Server portunu ana makinede rastgele boş bir porta yönlendirir ve yerel `~/.kube/config` dosyasına bu adresi yazar. Böylece host üzerindeki `kubectl`, doğrudan Docker konteynerine güvenli TLS bağlantısı kurabilir.

??? question "Soru 3: Bir Pod'u `kube-system` yerine `default` veya `training` namespace'inde çalıştırmanın avantajı nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        İzolasyon ve güvenlik. `kube-system` Kubernetes'in kritik kontrol bileşenlerini (DNS, etcd, apiserver) barındırır. Uygulama iş yüklerinin sistem pod'larıyla karışması hem kazara sistem servislerinin bozulmasına yol açabilir hem de RBAC (erişim yetkisi) ve kaynak kotası (ResourceQuota) yönetimini imkansız kılar.

---

## Beklenen Sonuç

```text
NAME                           STATUS   ROLES           AGE   VERSION
devops-cluster-control-plane   Ready    control-plane   2m    v1.29.x
devops-cluster-worker          Ready    <none>          2m    v1.29.x
devops-cluster-worker2         Ready    <none>          2m    v1.29.x
```

---

## Sorun Giderme

- **Docker daemon not running:** `docker info` komutunun başarılı çalıştığından emin olun.
- **Port 80/443 meşgul:** Host üzerinde Apache, Nginx veya eski Docker konteynerleri 80/443 portunu dinliyorsa durdurun (`sudo lsof -i :80`).
