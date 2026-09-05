# LAB-K8S-13 — Headlamp Kurulumu ve Salt Okunur Küme Erişimi

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 40 dakika | `kubernetes, helm` | `4466` |

[LAB-K8S-13.zip](/downloads/LAB-K8S-13.zip)


40 dakika | `kubernetes, helm` | `4466` |

## Amaç

- Headlamp’i Helm ile küme içine kurmak
- Port-forward ile yalnız yerel makineden erişmek
- Cluster-admin yerine salt okunur bir ServiceAccount ile oturum açmak
- Yetkili ve yasak işlemleri `kubectl auth can-i` ile kanıtlamak

## Ön Koşullar

```bash
kubectl cluster-info
helm version
```

Yerel `4466` portunun boş olduğundan emin olun.

## Mimari ve Çalışma Modeli

```text
Tarayıcı :4466 ── kubectl port-forward ── Headlamp Service ── Kubernetes API
                                                       └── headlamp-viewer RBAC
```

Headlamp, oturumdaki kimliğin Kubernetes RBAC izinlerini uygular. Lab hesabına yazma veya Secret okuma yetkisi verilmez.

## Adım Adım Uygulama Rehberi

### 1. Headlamp chart’ını kurun

```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo update
helm upgrade --install headlamp headlamp/headlamp \
  --namespace headlamp \
  --create-namespace \
  --wait \
  --timeout 5m

kubectl get deploy,pod,svc -n headlamp
```

### 2. Salt okunur hesabı oluşturun

```bash
cat <<'EOF' > headlamp-viewer-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: headlamp-viewer
  namespace: headlamp
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: headlamp-viewer
rules:
  - apiGroups: [""]
    resources: ["configmaps", "endpoints", "events", "namespaces", "nodes", "persistentvolumeclaims", "persistentvolumes", "pods", "pods/log", "replicationcontrollers", "services", "serviceaccounts"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["daemonsets", "deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["cronjobs", "jobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses", "networkpolicies"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: headlamp-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: headlamp-viewer
subjects:
  - kind: ServiceAccount
    name: headlamp-viewer
    namespace: headlamp
EOF

kubectl apply -f headlamp-viewer-rbac.yaml
```

### 3. RBAC sınırını doğrulayın

```bash
kubectl auth can-i list pods --all-namespaces \
  --as=system:serviceaccount:headlamp:headlamp-viewer
kubectl auth can-i delete pods --all-namespaces \
  --as=system:serviceaccount:headlamp:headlamp-viewer
kubectl auth can-i get secrets --all-namespaces \
  --as=system:serviceaccount:headlamp:headlamp-viewer
```

Çıktılar sırasıyla `yes`, `no`, `no` olmalıdır.

### 4. Headlamp’e bağlanın

Bir terminalde bağlantıyı açık tutun:

```bash
kubectl port-forward -n headlamp service/headlamp 4466:80
```

Başka bir terminalde kısa ömürlü oturum token’ı üretin:

```bash
kubectl create token headlamp-viewer -n headlamp --duration=1h
```

Tarayıcıdan `http://127.0.0.1:4466` adresini açın ve token ile giriş yapın. Pod ve Deployment listelerini görüntüleyin; silme/düzenleme işlemlerinin sunulmadığını doğrulayın.

## Doğal Doğrulama ve Beklenen Sonuç

```bash
helm status headlamp -n headlamp
kubectl rollout status deployment/headlamp -n headlamp --timeout=120s
curl -fsSI http://127.0.0.1:4466/
```

Helm release `deployed`, Deployment hazır ve HTTP isteği başarılı olmalıdır. Viewer hesabı kaynakları listeleyebilmeli; Pod silememeli ve Secret okuyamamalıdır.
