# LAB-HLM-01 — Örnek Uygulama için Helm Chart Oluşturma ve Dağıtma

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 60 dakika | `kubernetes, helm` | `8080` |

[LAB-HLM-01.zip](/downloads/LAB-HLM-01.zip)

## Amaç

- Bir HTTP örnek uygulaması için Helm chart dizinini ve Kubernetes şablonlarını oluşturmak.
- `values.yaml` ile imaj, replika, servis ve kaynak değerlerini parametreleştirmek.
- `helm lint` ve `helm template` ile cluster'a göndermeden önce manifestleri doğrulamak.
- Chart'ı kind Kubernetes kümesine dağıtmak, HTTP yanıtını kontrol etmek, upgrade ve rollback uygulamak.

## Ön Koşullar

- Çalışan kind kümesi ve `kubectl` (`[Kind kurulum rehberi](/setup/kind-cluster/)`).
- Helm 3 CLI (`helm version`).
- Docker Engine (`[Docker kurulumu](/setup/docker-engine/)`).
- Terminalde `~/labs/LAB-HLM-01` çalışma dizini.

## Mimari ve Çalışma Modeli

```text
values.yaml + templates/
          │ helm lint / helm template
          ▼
Helm release: prod-release (namespace: production)
          │
          ├── Deployment: 2 veya 4 replika
          └── ClusterIP Service: 80 → container 5678
                              │ kubectl port-forward :8080
                              ▼
                       http-echo örnek uygulaması
```

## Adım Adım Uygulama Rehberi

### Adım 1: Chart iskeletini oluşturun

```bash
mkdir -p ~/labs/LAB-HLM-01/devops-app/templates
cd ~/labs/LAB-HLM-01

cat <<'EOF' > devops-app/Chart.yaml
apiVersion: v2
name: devops-app
description: Helm ile dağıtılan basit HTTP uygulaması
type: application
version: 1.0.0
appVersion: "0.2.3"
EOF

cat <<'EOF' > devops-app/values.yaml
replicaCount: 2

image:
  repository: hashicorp/http-echo
  tag: "0.2.3"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 5678

appText: "Hello from Helm v1"

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi
EOF
```

### Adım 2: Deployment ve Service şablonlarını yazın

```bash
cat <<'EOF' > devops-app/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-web
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .Chart.Name }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ .Chart.Name }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: web
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          args: ["-text={{ .Values.appText }}", "-listen=:5678"]
          ports:
            - name: http
              containerPort: 5678
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 2
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
EOF

cat <<'EOF' > devops-app/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-web
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - name: http
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
EOF
```

### Adım 3: Chart'ı cluster'a göndermeden doğrulayın

```bash
helm lint devops-app
helm template devops-app devops-app
helm template devops-app devops-app | kubectl apply --dry-run=client --validate=false -f -
```

`helm lint` hatasız tamamlanmalı; render çıktısında `Deployment` ve `Service`
nesneleri, `containerPort: 5678` ve iki replika görünmelidir.

### Adım 4: İlk release'i Kubernetes'e dağıtın

```bash
helm upgrade --install prod-release devops-app \
  --namespace production \
  --create-namespace \
  --wait \
  --timeout 180s

kubectl rollout status deployment/prod-release-web -n production --timeout=180s
kubectl get deployment,pod,service -n production -l app.kubernetes.io/instance=prod-release
helm status prod-release -n production
```

### Adım 5: Gerçek HTTP yanıtını doğrulayın

```bash
kubectl port-forward -n production service/prod-release-web 8080:80 >/tmp/lab-hlm-01-port-forward.log 2>&1 &
PORT_FORWARD_PID=$!
trap 'kill "$PORT_FORWARD_PID" 2>/dev/null || true' EXIT
sleep 2
curl --fail --silent http://127.0.0.1:8080/
echo
```

Yanıtta `Hello from Helm v1` metnini görmelisiniz. Bu kontrol, yalnızca
manifest oluşturulduğunu değil, uygulamanın gerçekten servis üzerinden
yanıt verdiğini kanıtlar.

### Adım 6: Values ile upgrade yapın

```bash
cat <<'EOF' > prod-values.yaml
replicaCount: 4
appText: "Hello from Helm v2"
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 250m
    memory: 128Mi
EOF

helm upgrade prod-release devops-app -f prod-values.yaml --wait --timeout 180s
kubectl rollout status deployment/prod-release-web -n production --timeout=180s
kubectl get deployment prod-release-web -n production -o jsonpath='{.spec.replicas}{" replicas\n"}'
curl --fail --silent http://127.0.0.1:8080/
echo
helm history prod-release -n production
```

Yanıt `Hello from Helm v2` olmalı ve deployment dört replika göstermelidir.

### Adım 7: Önceki release'e rollback yapın

```bash
helm rollback prod-release 1 --wait --timeout 180s
kubectl rollout status deployment/prod-release-web -n production --timeout=180s
curl --fail --silent http://127.0.0.1:8080/
echo
helm status prod-release -n production
```

Yanıt tekrar `Hello from Helm v1` olmalıdır. `helm history` çıktısında ilk
kurulum, upgrade ve rollback için üç ayrı revizyon görünür.

## Doğal Doğrulama ve Beklenen Sonuç

```bash
helm status prod-release -n production
kubectl get pods -n production -l app.kubernetes.io/instance=prod-release
curl --fail --silent http://127.0.0.1:8080/
```

Release `deployed` durumunda, Pod'lar `Running/Ready`, servis yanıtı ise
rollback sonrasındaki `Hello from Helm v1` metnini içermelidir.
