# LAB-HLM-01 — Helm Fundamentals: Chart Structure, Custom Values & Release Management

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟡 **PRACTITIONER** (Orta Seviye) | ⏱️ 45 dakika | `kubernetes` | `Dahili / Küme İçi` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-HLM-01.zip)](/downloads/LAB-HLM-01.zip) — paket README ve başlangıç kodlarını içerir; çözüm içermez.
> 
> **Terminalde çalışma ortamını hazırlayın:**
> ```bash
> mkdir -p ~/labs/LAB-HLM-01
> cd ~/labs/LAB-HLM-01
> ```


## 1. Lab Senaryosu
Mikroservis sayısı arttıkça onlarca ham Kubernetes YAML dosyasını farklı ortamlar (geliştirme, test, üretim) için elle kopyalamak ve parametreleri güncellemek ciddi yapılandırma hatalarına yol açar. Helm, Kubernetes için paket yöneticisi olarak görev yaparak manifestoları dinamik Go şablonları (`templates/`) haline getirir ve ortama özel değerleri (`values.yaml`) parametrik olarak enjekte eder. Bu çalışmada sıfırdan kurumsal standartlarda bir Helm Chart hazırlanır; `helm lint` denetimi yapılır; üretim parametreleriyle (`values-prod.yaml`) 4 replikalı bir sürüm dağıtılır; canlı sistem üzerinde sürüm yükseltme (`upgrade`) ve geri alma (`rollback`) yaşam döngüsü doğrulanır.

## 2. Amaç
Helm v3 ile parametrik Chart mimarisi (`Chart.yaml`, `values.yaml`, `templates/`) oluşturmak, `helm lint` ve şablon render denetimi yapmak, üretim ortamına özel release dağıtmak, sürüm yükseltme ve önceki revizyona geri alma (rollback) adımlarını uygulamak.

## 3. Mimari / Akış
```text
  [ Helm Chart: devops-app ]
  ├── Chart.yaml (Metadata & Sürüm: 1.0.0)
  ├── values.yaml (Varsayılan Değerler: 2 Replika)
  ├── values-prod.yaml (Üretim Geçersiz Kılmaları: 4 Replika, Yüksek Kaynak)
  └── templates/
        ├── deployment.yaml  <-- (Parametrik Go Şablonu)
        └── service.yaml     <-- (Parametrik Servis Şablonu)
                |
                v (helm install / upgrade / rollback)
  [ Kubernetes Cluster: Release "prod-release" in Namespace "production" ]
```

## 4. Ön Koşullar
- `LAB-K8S-01` tamamlanmış ve kind cluster çalışıyor olmalıdır
- Helm v3 CLI (v3.21+) kurulu olmalıdır (`helm version`)
- `jq` aracı kurulu olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-K8S-01`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
helm version
kubectl cluster-info
mkdir -p ~/labs/LAB-HLM-01
cd ~/labs/LAB-HLM-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Helm Chart Dizin Yapısını ve Şablonlarını Oluşturma
Chart dizinini ve temel tanımları hazırlayın:
```bash
mkdir -p devops-app/templates

cat <<'EOF' > devops-app/Chart.yaml
apiVersion: v2
name: devops-app
description: Production-grade Helm Chart for DevOps Practitioner
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF

cat <<'EOF' > devops-app/values.yaml
replicaCount: 2

image:
  repository: hashicorp/http-echo
  pullPolicy: IfNotPresent
  tag: "0.2.3"

service:
  type: ClusterIP
  port: 80
  targetPort: 5678

appText: "Hello from Default Helm Values!"

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
EOF

cat <<'EOF' > devops-app/values-prod.yaml
replicaCount: 4
appText: "PRODUCTION WORKLOAD - High Availability Helm Release"
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 250m
    memory: 256Mi
EOF

cat <<'EOF' > devops-app/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
      release: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        release: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          args:
            - "-text={{ .Values.appText }}"
            - "-listen=:5678"
          ports:
            - name: http
              containerPort: 5678
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
EOF

cat <<'EOF' > devops-app/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-service
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
      name: http
  selector:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
EOF
```

### Adım 2 — Chart Sözdizimi Denetimi ve Şablon Render Testi
Şablon hatalarını doğrulamak için lint ve dry-run komutlarını çalıştırın:
```bash
# Şablon sözdizimi doğrulaması
helm lint devops-app/

# Üretim değerleriyle derlenen ham Kubernetes manifestini görüntüle
helm template my-test-release devops-app/ -f devops-app/values-prod.yaml
```

### Adım 3 — Üretim Release'ini Kümede Dağıtma
`production` ad alanını açarak 4 replikalı üretim sürümünü kurun:
```bash
helm install prod-release devops-app/ -f devops-app/values-prod.yaml --create-namespace -n production
helm status prod-release -n production
kubectl get pods -n production
```

### Adım 4 — Sürüm Yükseltme ve Geri Alma (Rollback)
Uygulama metnini güncelleyerek sürümü yükseltin, ardından ilk revizyona geri dönün:
```bash
# Sürümü yükselt
helm upgrade prod-release devops-app/ --set appText="UPGRADED TO V2 VIA HELM" -n production

# Sürüm geçmişini incele
helm history prod-release -n production

# Revizyon 1'e geri dön (Rollback)
helm rollback prod-release 1 -n production
```

## 6. Beklenen Sonuç
Adım 2'deki lint çıktısı:
```text
1 chart(s) linted, 0 chart(s) failed
```

Adım 3'teki release durumu ve pod sayısı:
```text
STATUS: deployed
REVISION: 1
... 4/4 pods running
```

Adım 4'teki sürüm geçmişi:
```text
REVISION  UPDATED   STATUS      CHART             APP VERSION  DESCRIPTION     
1         ...       superseded  devops-app-1.0.0  1.0.0        Install complete
2         ...       superseded  devops-app-1.0.0  1.0.0        Upgrade complete
3         ...       deployed    devops-app-1.0.0  1.0.0        Rollback to 1
```

## 8. Sorun Giderme

### Belirti
`helm lint` veya `helm install` komutu verilirken `error converting YAML to JSON: yaml: line X: did not find expected key` hatası alınır.

### Kanıt
Helm şablon render aşamasında YAML girinti (indentation) hatası oluştuğu bildirilir.

### Kontrol Komutu
```bash
helm template test devops-app/
```

### Muhtemel Neden
`{{- toYaml .Values.resources | nindent 12 }}` satırındaki `nindent` boşluk sayısı Kubernetes spec hiyerarşisine uymamaktadır.

### Çözüm
`templates/deployment.yaml` dosyasındaki `nindent` değerini hiyerarşiye uygun olarak 12 boşluğa ayarlayın.

### Tekrar Doğrulama
```bash
helm lint devops-app/
# "0 chart(s) failed" çıktısı alınmalıdır.
```

## 10. Production Notu
Üretim ortamlarında Chart sürümleri semantik versiyonlama kuralına (`version: 1.2.0`) göre her değişiklikte artırılmalıdır. Parametrelerin güvenliği ve veri doğrulaması için `values.schema.json` şeması tanımlanmalı, paketlenen Chart'lar Harbor veya OCI uyumlu bir Artifact Registry üzerinde (`helm push`) versiyonlanmalıdır.

## 11. Challenge
Chart şablonlarına `templates/tests/test-connection.yaml` entegrasyon test podu ekleyerek `helm test prod-release -n production` komutuyla çalışan servise otomatik ping testi atın.
