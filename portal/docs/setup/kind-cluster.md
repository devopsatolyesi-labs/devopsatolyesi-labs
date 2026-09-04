# kind (Kubernetes in Docker) ile Yerel Küme Kurulumu

Bu rehber, Docker üzerinde çalışan hafif, çok düğümlü (multi-node) bir **Kubernetes kümesinin** `kind` (Kubernetes in Docker) aracı kullanılarak adım adım kurulumunu ve yönetimini açıklar.

---

## 1. Ön Koşullar

- Docker Engine kurulu ve çalışır durumda olmalıdır (`docker ps`).
- `kubectl` aracı kurulu olmalıdır.

```bash
# kubectl kurulumu (Linux amd64)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
```

---

## 2. kind CLI Kurulumu

```bash
# En güncel kind ikili dosyasını indirin
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version
```

---

## 3. Çok Düğümlü (1 Control-Plane + 2 Worker) Küme Oluşturma

Tek düğüm yerine gerçekçi testler yapabilmek için 1 control-plane ve 2 worker düğümlü bir küme yapılandırma dosyası oluşturalım:

```bash
cat <<EOF > ~/kind-cluster-config.yaml
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
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
  - role: worker
  - role: worker
EOF
```

### Kümeyi Başlatın:

```bash
kind create cluster --config ~/kind-cluster-config.yaml
```

---

## 4. Küme Durumunu Doğrulama

```bash
# Düğümlerin durumunu inceleyin
kubectl get nodes -o wide

# Sistem podlarının durumunu kontrol edin
kubectl get pods -n kube-system

# Küme bilgilerini alın
kubectl cluster-info
```

Tüm düğümler `Ready` durumuna geçtiğinde yerel Kubernetes kümeniz hazırdır.

---

## 5. Ingress NGINX Controller Kurulumu (Opsiyonel)

Kümeye dışarıdan HTTP/HTTPS trafiği almak için resmi kind Ingress Controller kurun:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Ingress podunun hazır olmasını bekleyin
kubectl wait --namespace ingress-nginx   --for=condition=ready pod   --selector=app.kubernetes.io/component=controller   --timeout=120s
```

---

## 6. Kümeyi Silme ve Sıfırlama

```bash
# Kümeyi tamamen silmek için
kind delete cluster --name devops-cluster
```
