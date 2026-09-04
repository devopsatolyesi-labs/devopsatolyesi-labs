# Argo CD Kurulumu ve GitOps Yapılandırması

Bu rehber, Kubernetes üzerinde bildirimsel (declarative) GitOps continuous delivery sağlamak için **Argo CD** bileşeninin kurulumunu, Web UI ve CLI erişimini adım adım açıklar.

---

## 1. Argo CD Kurulumu (Kubernetes)

```bash
# ArgoCD namespace oluşturun ve resmi manifesti uygulayın
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Tüm podların hazır olmasını bekleyin
kubectl wait --namespace argocd   --for=condition=ready pod   --all --timeout=180s
```

---

## 2. Argo CD Web UI Erişimi

Web UI arayüzüne erişmek için servisi NodePort veya Port-Forward ile açabilirsiniz:

```bash
# Yöntem A: Port-Forward (Geçici & Hızlı Erişim)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Yöntem B: NodePort Servis Dönüşümü (Kalıcı Erişim)
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
NODE_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
echo "Argo CD Web UI Portu: $NODE_PORT"
```

---

## 3. Başlangıç Admin Şifresini Alma

Argo CD varsayılan kullanıcı adı `admin`dir. Şifre secret içerisinden okunur:

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo
```

---

## 4. Argo CD CLI Kurulumu ve Giriş

```bash
# CLI ikili dosyasını indirin
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# CLI ile giriş yapın
argocd login localhost:8080 --username admin --insecure
```
