# LAB-K8S-01 — kind Multi-Node Cluster Setup & kubectl Preflight

## Metadata
- **Seviye:** CORE
- **Önerilen Gün:** Gün 4
- **Tahmini Süre:** 45 dk
- **Gerekli Profil:** `kubernetes`
- **Host Portları:** `80:80`, `443:443` (Ingress ExtraPortMappings)
- **Çalışma Dizini:** `~/labs/LAB-K8S-01`

---

## 1. Lab Senaryosu
Modern mikroservis mimarilerinde konteynerlerin ölçeklenmesi, yüksek erişilebilirliği ve otomatik kendini onarma (self-healing) yetenekleri bir orkestratör gerektirir. Kubernetes, bulut yerel dünyanın fiili standardıdır. Geliştirme ve test süreçlerinde harici bir bulut sağlayıcıya (EKS/GKE) bağımlı olmadan çok düğümlü üretim benzeri bir küme kurmak için `kind` (Kubernetes in Docker) kullanılır. Bu çalışmada 1 Control-Plane ve 2 Worker düğümünden oluşan Kubernetes v1.31 kümesi kurulur; kubeadm v1beta4 yamaları uygulanır; bağımsız Pod ile deklaratif Deployment arasındaki farklar ve self-healing mekanizması canlı olarak test edilir.

## 2. Amaç
`kind` kullanarak 3 düğümlü yerel Kubernetes v1.31 kümesi oluşturmak, `kubeadm.k8s.io/v1beta4` formatında konfigürasyon uygulamak, `kubectl` ile düğüm durumlarını denetlemek ve deklaratif Deployment üzerinde pod silme simülasyonu yaparak self-healing yeteneğini doğrulamak.

## 3. Mimari / Akış
```text
  [ Host: Ubuntu 24.04 (Docker 27.x) ]
                       |
                       v
  +-----------------------------------------------------------+
  | kind Cluster: "devops-cluster" (Kubernetes v1.31.9)       |
  |                                                           |
  |  [ Control-Plane Node ]                                   |
  |   - API Server, etcd, Scheduler, Controller Manager       |
  |   - Ingress Ready (Extra Port Mappings: 80, 443)          |
  |                                                           |
  |  [ Worker Node 1 ]                [ Worker Node 2 ]       |
  |   - Pod: payment-api (Replica 1)   - Pod: payment-api (R2)|
  |   - Pod: payment-api (Replica 3)                          |
  +-----------------------------------------------------------+
```

```mermaid
flowchart TD
    subgraph HOST [Ubuntu 24.04 Host - Docker Daemon]
        P80[Port: 80 / 443 HTTP/S]
        P8088[Port: 8088 Dashboard]
        
        subgraph CLUSTER [kind: devops-cluster (v1.31.9)]
            subgraph CP [Control-Plane Node Container]
                API[API Server :6443]
                ETCD[etcd]
                SCHED[Kube-Scheduler]
            end

            subgraph W1 [Worker Node 1 Container]
                POD1[Pod: payment-api #1]
                POD2[Pod: payment-api #2]
            end

            subgraph W2 [Worker Node 2 Container]
                POD3[Pod: payment-api #3]
            end
        end

        HEADLAMP[Headlamp Web UI :8088]
    end

    P80 -->|Ingress Port Map| CP
    P8088 --> HEADLAMP
    HEADLAMP -.->|kubeconfig| API
    API --> W1
    API --> W2

    classDef host fill:#0f172a,stroke:#334155,color:#fff;
    classDef cp fill:#1e1b4b,stroke:#818cf8,color:#fff;
    classDef worker fill:#064e3b,stroke:#34d399,color:#fff;

    class CP cp;
    class W1,W2 worker;
```

> [!NOTE]
> `kind` (Kubernetes in Docker), her bir küme düğümünü (Control Plane ve Worker) bağımsız bir Docker konteyneri içinde çalıştırır. `extraPortMappings` direktifi ile hostun 80 ve 443 portları doğrudan control-plane düğümüne köprülenerek Ingress trafiğine hazır hale getirilir.


## 4. Ön Koşullar
- Docker Engine çalışır durumda olmalıdır
- `kind` CLI (v0.30.0+) ve `kubectl` CLI (v1.31+) kurulu olmalıdır
- Host üzerinde 80 ve 443 portları boş olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-DOC-01`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
kind version
kubectl version --client --output=yaml
docker ps
mkdir -p ~/labs/LAB-K8S-01/manifests
cd ~/labs/LAB-K8S-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Çok Düğümlü kind Yapılandırma Dosyasını Hazırlama
Ingress port yönlendirmesi ve `kubeadm.k8s.io/v1beta4` API sürümünü içeren küme tanımını oluşturun:
```yaml
cat <<'EOF' > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: devops-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        apiVersion: kubeadm.k8s.io/v1beta4
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

### Adım 2 — Kubernetes Kümesini Başlatma ve Düğümleri Denetleme
Kümeyi sabitlenmiş `kindest/node:v1.31.4` imajı ile ayağa kaldırın ve düğüm durumlarını listeleyin:
```bash
kind create cluster --config kind-config.yaml --image kindest/node:v1.31.4
kubectl get nodes -o wide
```

### Adım 3 — Temel Pod Manifesti Oluşturma ve Yaşam Döngüsü
Yönetilmeyen (standalone) bir pod oluşturup durumunu izleyin:
```yaml
cat <<'EOF' > manifests/pod-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: standalone-web
  labels:
    app: standalone-web
    tier: frontend
spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
EOF
```

```bash
kubectl apply -f manifests/pod-basic.yaml
kubectl wait --for=condition=Ready pod/standalone-web --timeout=60s
kubectl get pods
```

### Adım 4 — Deklaratif Deployment Tanımlama ve Rollout
3 replikalı kendini onaran Deployment nesnesini oluşturun:
```yaml
cat <<'EOF' > manifests/deployment-resilient.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api-deployment
  labels:
    app: payment-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
    spec:
      containers:
        - name: api
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=Payment API Microservice is Live on K8s 1.31!"
          ports:
            - containerPort: 5678
EOF
```

```bash
kubectl apply -f manifests/deployment-resilient.yaml
kubectl rollout status deployment/payment-api-deployment
kubectl get pods -l app=payment-api -o wide
```

### Adım 5 — Self-Healing Testi: Pod Silme ve Otomatik Kurtarma
Çalışan podlardan birini silerek Deployment Controller'ın anında yeni bir pod başlattığını gözlemleyin:
```bash
POD_TO_KILL=$(kubectl get pods -l app=payment-api -o jsonpath='{.items[0].metadata.name}')
echo "Sonlandirilan Pod: $POD_TO_KILL"
kubectl delete pod "$POD_TO_KILL"

# Replikaların yeniden 3/3 olduğunu gözlemle
kubectl get pods -l app=payment-api
```

## 6. Beklenen Sonuç
Adım 2'deki düğüm listesi çıktısı:
```text
NAME                           STATUS   ROLES           AGE   VERSION   INTERNAL-IP
devops-cluster-control-plane   Ready    control-plane   ...   v1.31.4   ...
devops-cluster-worker          Ready    <none>          ...   v1.31.4   ...
devops-cluster-worker2         Ready    <none>          ...   v1.31.4   ...
```

Adım 4'teki Deployment rollout çıktısı:
```text
deployment "payment-api-deployment" successfully rolled out
```

Adım 5'te pod silindikten sonra replikaların durumu:
```text
NAME                                      READY   STATUS    RESTARTS   AGE
payment-api-deployment-xxxxxxxxxx-new     1/1     Running   0          3s
payment-api-deployment-xxxxxxxxxx-2       1/1     Running   0          ...
payment-api-deployment-xxxxxxxxxx-3       1/1     Running   0          ...
```


---

## 🛠️ En Çok Kullanılan `kubectl` Komutları ve Pratik İpuçları (Cheat Sheet)

Kubernetes küme yönetiminde, sertifikasyon sınavlarında (CKA/CKAD) ve canlı operasyonlarda hız kazandıran temel komut seti:

### 1. Hızlı Kaynak Görüntüleme ve Filtreleme
```bash
# Tüm ad alanlarındaki Pod'ları IP ve Node bilgileriyle listeleme
kubectl get pods -A -o wide

# Belirli bir etiket (label) seçicisine uyan servisleri bulma
kubectl get pods -l app=payment-api --show-labels

# Pod veya Deployment'ın detaylı durumunu, event (olay) kayıtlarını inceleme
kubectl describe pod <pod-name> -n <namespace>

# Kaynağın YAML çıktısını alma (konfigürasyon kopyalamak için)
kubectl get deployment payment-api -o yaml > deployment-backup.yaml
```

### 2. Hızlı Bildirimsel (Declarative) Şablon Üretimi (`--dry-run=client`)
```bash
# Sıfırdan YAML yazmak yerine şablon üretme (Zaman kazandırıcı CKA taktiği)
kubectl run nginx-pod --image=nginx:alpine --dry-run=client -o yaml > pod.yaml

# 3 replikalı Deployment manifestosu üretme
kubectl create deployment web-api --image=nginx:alpine --replicas=3 --dry-run=client -o yaml > deployment.yaml

# Deployment için NodePort servisi üretme
kubectl expose deployment web-api --port=80 --target-port=8080 --type=NodePort --dry-run=client -o yaml > service.yaml
```

### 3. Canlı Sorun Giderme ve Debug
```bash
# Çalışan bir konteynerin içine interaktif kabuk açma
kubectl exec -it <pod-name> -- sh

# Çöken veya yeniden başlayan konteynerin önceki loglarını inceleme
kubectl logs <pod-name> --previous -c <container-name>

# Kümedeki bir servisi geçici olarak yerel bilgisayara yönlendirme
kubectl port-forward svc/payment-service 8080:8000 &
```

### 4. Güncelleme, Rollout ve Ölçekleme
```bash
# Deployment imajını canlıda güncelleme
kubectl set image deployment/web-api nginx=nginx:1.25-alpine

# Dağıtım durumunu izleme ve geçmişi görme
kubectl rollout status deployment/web-api
kubectl rollout history deployment/web-api

# Hatalı bir dağıtımı anında önceki sürüme geri alma (Rollback)
kubectl rollout undo deployment/web-api

# Pod'ları sırayla yeniden başlatma (Rolling Restart)
kubectl rollout restart deployment/web-api

# Replika sayısını anında artırma
kubectl scale deployment/web-api --replicas=5
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: Bir pod `CrashLoopBackOff` durumuna düştüğünde ve `kubectl logs <pod-name>` komutu boş döndüğünde, çökmeden hemen önceki hata mesajını görmek için hangi bayrak kullanılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `--previous` bayrağı kullanılır:
        ```bash
        kubectl logs <pod-name> --previous
        ```
        Pod çöktükten sonra Kubernetes yeni bir konteyner başlattığı için standart logs komutu henüz yeni başlayan boş konteyneri dinler. `--previous` parametresi ise az önce çöken ve sonlanan konteynerin stdout/stderr çıktısını getirir.

??? question "Soru 2: `kubectl run` komutu ile `kubectl create deployment` komutu arasındaki mimari fark nedir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        - `kubectl run`, doğrudan bağımsız (bare/standalone) tek bir **Pod** nesnesi oluşturur. Pod silinirse veya düğüm çökerse Kubernetes onu yeniden başlatmaz (self-healing yoktur).
        - `kubectl create deployment`, bir **Deployment** denetleyicisi ve onun altında bir **ReplicaSet** oluşturur. Pod çökerse veya silinirse ReplicaSet anında istenen durumu (desired state) korumak için yeni bir pod ayağa kaldırır.

??? question "Soru 3: Kümedeki tüm pod'ların CPU ve RAM tüketimini anlık olarak görmek için hangi komut kullanılır ve bu komutun çalışması için kümede hangi bileşenin kurulu olması gerekir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        Komut:
        ```bash
        kubectl top pods -A
        kubectl top nodes
        ```
        Bu komutun çalışabilmesi için kümede **Kubernetes Metrics Server** bileşeninin kurulu ve pod metriklerini topluyor olması zorunludur.

??? question "Soru 4: Production ortamında çalışan bir pod'a zarar vermeden içerisindeki `/app/config.json` dosyasını yerel bilgisayarınıza nasıl kopyalarsınız?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `kubectl cp` komutu kullanılır:
        ```bash
        kubectl cp <pod-name>:/app/config.json ./config-local.json
        ```

??? question "Soru 5: Hızlıca test yapmak için pod çalıştırmak ve işimiz bitince otomatik silinmesini sağlamak için hangi parametreler verilir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `--rm -it` parametreleri kullanılır:
        ```bash
        kubectl run curl-test --rm -it --image=curlimages/curl -- sh
        ```
        Bu komut kabuktan çıkıldığı (`exit`) anda pod nesnesini kümeden otomatik olarak temizler.


## 7. Doğrulama
Kümedeki 3 düğümün Ready olduğunu ve Deployment'ın 3 sağlıklı podunun çalıştığını doğrulayın:
```bash
READY_NODES=$(kubectl get nodes --no-headers | grep -c "Ready")
READY_PODS=$(kubectl get deployment payment-api-deployment -o jsonpath='{.status.readyReplicas}')

if [ "$READY_NODES" -ge 3 ] && [ "$READY_PODS" -eq 3 ]; then
  echo "VALIDATION SUCCESS: kind cluster is healthy with 3 nodes (K8s v1.31.4), and 3/3 deployment replicas are running."
else
  echo "VALIDATION FAILED: Nodes: $READY_NODES, Pods: $READY_PODS" && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
`kind create cluster` komutu verilirken `unknown field "nodeRegistration" in kubeadmInitConfiguration` hatası alınır.

### Kanıt
`kind-config.yaml` dosyasında `apiVersion: kubeadm.k8s.io/v1beta3` yazmaktadır.

### Kontrol Komutu
```bash
grep -i "apiVersion: kubeadm" kind-config.yaml
```

### Muhtemel Neden
Kubernetes 1.31+ sürümlerinde eski `v1beta3` API sürümü kaldırılmıştır.

### Çözüm
Yama başlığını `apiVersion: kubeadm.k8s.io/v1beta4` olarak güncelleyin ve kümeyi tekrar başlatın.

### Tekrar Doğrulama
```bash
kind create cluster --config kind-config.yaml --image kindest/node:v1.31.4
```

## 9. Temizlik / Sıfırlama
Oluşturulan Kubernetes kaynaklarını ve kind kümesini silin:
```bash
kubectl delete -f manifests/deployment-resilient.yaml manifests/pod-basic.yaml 2>/dev/null || true
kind delete cluster --name devops-cluster 2>/dev/null || true
rm -rf ~/labs/LAB-K8S-01
```

## 10. Production Notu
Üretim ortamlarında doğrudan `kind: Pod` nesneleri oluşturulmaz (Bare Pods); podun çökmesi durumunda tekrar başlatılması ve farklı worker düğümlere dağıtılması için her zaman `Deployment` veya `StatefulSet` kullanılır. Düğümler arası dengeli dağıtım için `topologySpreadConstraints` veya `podAntiAffinity` kuralları tanımlanmalıdır.

## 11. Challenge
`kubectl port-forward deployment/payment-api-deployment 8080:5678` komutunu arka planda çalıştırarak host üzerinden `curl http://localhost:8080` ile podların HTTP yanıtını doğrulayın.
