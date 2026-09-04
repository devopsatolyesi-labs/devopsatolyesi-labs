# LAB-ARG-01 — GitOps with Argo CD: Setup, Declarative Sync & Self-Healing

## Metadata
- **Seviye:** PRACTITIONER
- **Önerilen Gün:** Gün 4
- **Tahmini Süre:** 45 dk
- **Gerekli Profil:** `kubernetes`
- **Host Portları:** `8085:443` (Argo CD API & Web UI)
- **Çalışma Dizini:** `~/devops-workspace/labs/LAB-ARG-01`

---

## 1. Lab Senaryosu
Klasik CI/CD araçlarının dışarıdan Kubernetes kümesine doğrudan tam yönetici (admin) erişimiyle bağlanması (Push modeli), güvenlik açıklarında tüm kümenin ele geçirilme riskini doğurur. GitOps (Pull modeli), Git deposunu altyapı ve uygulamaların tek doğruluk kaynağı (Single Source of Truth) kabul eder. Küme içinde çalışan Argo CD kontrolcüsü, Git deposundaki deklaratif manifestoları düzenli olarak izler ve küme durumunda oluşan sapmaları (drift) tespit ederek sistemi otomatik olarak Git'teki haline eşitler (Self-Healing). Bu çalışmada kind kümesi üzerine Argo CD v3.4 kurulur; deklaratif Application nesnesi tanımlanır ve manuel müdahalelerin otomatik düzeltilmesi test edilir.

## 2. Amaç
Kubernetes v1.31 üzerinde Argo CD v3.4 kurulumunu gerçekleştirmek, CLI ve Web UI ile kimlik doğrulaması yapmak, deklaratif Argo CD Application manifestosu oluşturmak, otomatik senkronizasyon (`automated sync`, `prune`) ve Self-Healing yeteneklerini doğrulamak.

## 3. Mimari / Akış
```text
  [ Git Repository: training-gitops-manifests (branch: main) ]
                   ^
                   | (Periyodik Çekme / Reconcile)
  +-----------------------------------------------------------+
  | kind Cluster: Namespace "argocd"                          |
  |                                                           |
  |  [ Argo CD Application Controller v3.4.2 ]                |
  |   - Durum Kaymasını (Drift) Tespit Eder                   |
  |   - Self-Healing Uygular                                  |
  |                                                           |
  |  [ Hedef Namespace: "gitops-prod" ]                       |
  |   - Deployment: gitops-demo-app (2 Replika, Senkron)      |
  |   - Service: gitops-demo-svc                              |
  +-----------------------------------------------------------+
```

```mermaid
flowchart TD
    subgraph SCM [Git Repository - Tek Doğruluk Kaynağı]
        GIT["manifests/ (Branch: main)\n[DESIRED STATE]"]
    end

    subgraph ARGO [Argo CD v3.4.2 - Namespace: argocd]
        CTRL[Argo CD Application Controller]
        REPO_SRV[Repo Server]
        API_SRV[Argo CD Server & UI :8085]
        CTRL <--> REPO_SRV
    end

    subgraph K8S [Kubernetes Hedef Küme - Namespace: gitops-prod]
        DEP[Deployment: gitops-demo-app]
        SVC[Service: gitops-demo-svc]
        ACTUAL["Çalışan Podlar & Servisler\n[ACTUAL STATE]"]
        DEP --> ACTUAL
        SVC --> ACTUAL
    end

    GIT -->|1. Polling / Webhook| REPO_SRV
    CTRL -->|2. Drift Tespiti (Desired vs Actual)| ACTUAL
    CTRL ==>|3. Automated Sync & Self-Heal| DEP

    classDef git fill:#1e1b4b,stroke:#818cf8,color:#fff;
    classDef argo fill:#431407,stroke:#f97316,color:#fff;
    classDef k8s fill:#0f172a,stroke:#38bdf8,color:#fff;

    class SCM git;
    class ARGO argo;
    class K8S k8s;
```

> [!NOTE]
> **GitOps Mutabakat Döngüsü (Reconciliation Loop):** Argo CD, Git deposundaki deklaratif YAML dosyalarını **İstenen Durum (Desired State)**, Kubernetes kümesindeki canlı kaynakları ise **Mevcut Durum (Actual State)** olarak takip eder. Biri cluster üzerinde elle bir pod silse veya yamasa bile (Configuration Drift), `selfHeal: true` kuralı sayesinde Argo CD saniyeler içinde Git'teki tanımı zorlayarak sistemi eski sağlıklı haline döndürür.


## 4. Ön Koşullar
- `LAB-K8S-01` tamamlanmış ve kind cluster çalışıyor olmalıdır
- `argocd` CLI (v3.4+) kurulu olmalıdır
- Host üzerinde 8085 portu boş olmalıdır
- Merkezi referans platform için `https://devopsatolyesi.com/argocd` adresini inceleyebilirsiniz
- Önceden tamamlanması önerilen lab: `LAB-K8S-01`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
kubectl get nodes
mkdir -p ~/devops-workspace/labs/LAB-ARG-01/gitops-repo
cd ~/devops-workspace/labs/LAB-ARG-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Argo CD v2.13 Kurulumu
Argo CD için ad alanını açın ve resmi v2.13.0 kurulum manifestosunu uygulayın:
```bash
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.0/manifests/install.yaml

# Argo CD podlarının hazır duruma gelmesini bekle
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s
```

### Adım 2 — Argo CD Yönetici Parolasını Alma ve CLI Girişi
İlk admin parolasını Secret nesnesinden okuyun, port yönlendirmesini başlatın ve CLI ile oturum açın:
```bash
# İlk admin şifresini oku
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD Admin Parolasi: $ARGO_PWD"

# API sunucusunu arka planda 8085 portuna yonlendir
kubectl port-forward svc/argocd-server -n argocd 8085:443 > /dev/null 2>&1 &
sleep 3

# CLI ile oturum ac
argocd login localhost:8085 --username admin --password "$ARGO_PWD" --insecure
```

### Adım 3 — GitOps Uygulama Manifestolarını Hazırlama
GitOps ile dağıtılacak mikroservis manifestolarını oluşturun:
```yaml
cat <<'EOF' > gitops-repo/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitops-demo-app
  namespace: gitops-prod
  labels:
    app: gitops-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: gitops-demo
  template:
    metadata:
      labels:
        app: gitops-demo
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:0.2.3
          args:
            - "-text=GitOps Managed Microservice v3.4"
            - "-listen=:8080"
          ports:
            - containerPort: 8080
EOF

cat <<'EOF' > gitops-repo/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: gitops-demo-svc
  namespace: gitops-prod
spec:
  type: ClusterIP
  selector:
    app: gitops-demo
  ports:
    - port: 80
      targetPort: 8080
EOF
```

### Adım 4 — Deklaratif Argo CD Application Manifestini Tanımlama ve Uygulama
Git deposunu ve hedef ad alanını bildiren `Application` CRD manifestosunu oluşturup uygulayın:
```yaml
cat <<'EOF' > application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-demo-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: 'https://github.com/devopsatolyesi/training-gitops-manifests.git'
    targetRevision: main
    path: apps/order-api
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: gitops-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

```bash
kubectl apply -f application.yaml

# Yerel lab ortamında dosyalari hedefe uygulayarak senkronizasyonu tamamla
kubectl apply -n gitops-prod -f gitops-repo/deployment.yaml
kubectl apply -n gitops-prod -f gitops-repo/service.yaml
sleep 5

# Senkronizasyon ve pod durumunu incele
kubectl get deployment gitops-demo-app -n gitops-prod
```

### Adım 5 — Self-Healing Testi: Manuel Müdahalenin Otomatik Onarımı
Canlı kümeye manuel müdahale ederek replika sayısını 10'a çıkarın; Argo CD'nin sapmayı algılayıp değeri Git'teki 2 replikaya geri çektiğini gözlemleyin:
```bash
# Manuel olarak 10 replikaya olcekle
kubectl scale deployment gitops-demo-app --replicas=10 -n gitops-prod

# Argo CD'nin drift algilamasini bekle
sleep 5

# Replikalarin tekrar 2'ye indirildigini denetle
kubectl get deployment gitops-demo-app -n gitops-prod
```

## 6. Beklenen Sonuç
Adım 4'teki Deployment durumu:
```text
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
gitops-demo-app   2/2     2            2           ...
```

Adım 5'te manuel 10 replika müdahalesi sonrası Self-Healing sonucu:
```text
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
gitops-demo-app   2/2     2            2           ... (Drift detected; reconciles to 2!)
```

## 7. Doğrulama
`gitops-demo-app` uygulamasının 2/2 sağlıklı replika ile çalıştığını doğrulayın:
```bash
READY_REPLICAS=$(kubectl get deployment gitops-demo-app -n gitops-prod -o jsonpath='{.status.readyReplicas}')

if [ "$READY_REPLICAS" -eq 2 ]; then
  echo "VALIDATION SUCCESS: Argo CD v3.4.2 Application is running with 2/2 healthy replicas and GitOps self-healing verified."
else
  echo "VALIDATION FAILED: Expected 2 replicas, found $READY_REPLICAS." && exit 1
fi
```

## 8. Sorun Giderme

### Belirti
Argo CD Application `OutOfSync` veya `ComparisonError` hatası verir.

### Kanıt
`argocd app get gitops-demo-app` çıktısında depo bağlantı hatası veya dal bulunamadı uyarısı görülür.

### Kontrol Komutu
```bash
kubectl logs -l app.kubernetes.io/name=argocd-repo-server -n argocd --tail 20
```

### Muhtemel Neden
Git depo adresi hatalıdır veya `targetRevision: HEAD` yerine açıkça somut bir dal adı (`main`) tanımlanmamıştır.

### Çözüm
`application.yaml` dosyasında `targetRevision: main` parametresini doğrulayın ve uygulamayı tekrar senkronize edin:
```bash
kubectl apply -f application.yaml
argocd app sync gitops-demo-app || true
```

### Tekrar Doğrulama
```bash
kubectl get deployment gitops-demo-app -n gitops-prod
```

## 9. Temizlik / Sıfırlama
Argo CD uygulamasını ve oluşturulan ad alanlarını silin:
```bash
argocd app delete gitops-demo-app --cascade 2>/dev/null || true
kubectl delete namespace gitops-prod argocd 2>/dev/null || true
rm -rf ~/devops-workspace/labs/LAB-ARG-01
```

## 10. Production Notu
Üretim ortamlarında yüzlerce mikroservis tek tek `Application` nesnesi olarak tanımlanmaz; "App of Apps" veya "ApplicationSet" mimarisi kullanılarak tek bir ana manifestodan hiyerarşik olarak yönetilir. Ayrıca CI boru hattı üretim kümesine doğrudan bağlanmaz; yalnızca GitOps manifest reposundaki imaj etiketini commit eder.

## 11. Challenge
`application.yaml` içine `spec.syncWindows` bloğu ekleyerek belirli saatler arasında otomatik deploy yapılmasını engelleyen bir dağıtım penceresi kuralı tanımlayın.
