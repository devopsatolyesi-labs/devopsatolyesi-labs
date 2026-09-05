# LAB-HLM-02 — Helm Dependencies, Subcharts ve Lifecycle Hooks

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| İleri | 75 dakika | `kubernetes, helm` | `8081` |

[LAB-HLM-02.zip](/downloads/LAB-HLM-02.zip)

## Amaç

- Bir ana chart'ın yerel subchart bağımlılığını `Chart.yaml` üzerinden yönetmek.
- Ana chart değerlerini subchart'a güvenli ve açık bir values ağacıyla geçirmek.
- `pre-install` ve `pre-upgrade` hook ile migration benzeri hazırlık adımını release yaşam döngüsüne bağlamak.
- Bağımlı bileşen, ana uygulama ve hook loglarını gerçek Kubernetes komutlarıyla doğrulamak.

## Neden Önemli?

Gerçek uygulamalar tek bir Deployment'tan oluşmaz. API'nin yanında cache,
veritabanı veya queue gibi bileşenler bulunur. Dependencies ve subcharts bu
bileşenleri tekrar kullanılabilir paketler halinde yönetir. Hooks ise release
kurulmadan önce migration, şema kontrolü veya hazırlık gibi tek seferlik işleri
çalıştırır. Bu lab, temel `helm install` bilgisini üretim release desenlerine
taşır; ancak hook'lar kontrollü kullanılmalıdır çünkü her upgrade'de çalışan
uzun veya başarısız bir hook release'i bloke eder.

## Ön Koşullar

- Çalışan kind kümesi ve `kubectl` (`[Kind kurulumu](/setup/kind-cluster/)`).
- Helm 3 CLI (`helm version`).
- Docker Engine.
- `LAB-HLM-01` tamamlanmış olmalıdır.

## Mimari ve Çalışma Modeli

```text
orders-platform (ana chart)
  ├── web Deployment + Service (http-echo)
  ├── pre-install / pre-upgrade Hook Job (migration-check)
  └── charts/cache (yerel subchart)
        └── Redis Deployment + ClusterIP Service

helm dependency build
        │
        ▼
helm upgrade --install --wait
  1. Hook Job tamamlanır
  2. Redis subchart kaynakları uygulanır
  3. Web Deployment hazır olur
  4. Service üzerinden HTTP yanıtı doğrulanır
```

## Adım Adım Uygulama Rehberi

### Adım 1: Ana chart ve yerel dependency tanımını oluşturun

```bash
mkdir -p ~/labs/LAB-HLM-02/orders-platform/{templates,charts/cache/templates}
cd ~/labs/LAB-HLM-02

cat <<'EOF' > orders-platform/Chart.yaml
apiVersion: v2
name: orders-platform
description: Ana HTTP uygulaması ve yerel cache subchart'ı
type: application
version: 1.0.0
appVersion: "0.2.3"
dependencies:
  - name: cache
    version: 0.1.0
    repository: file://charts/cache
    condition: cache.enabled
EOF

cat <<'EOF' > orders-platform/values.yaml
replicaCount: 2

image:
  repository: hashicorp/http-echo
  tag: "0.2.3"
  pullPolicy: IfNotPresent

service:
  port: 80
  targetPort: 5678

appText: "orders-platform release v1"

cache:
  enabled: true
  replicaCount: 1
  image:
    repository: redis
    tag: "7.4-alpine"
    pullPolicy: IfNotPresent
  service:
    port: 6379
EOF

cat <<'EOF' > orders-platform/charts/cache/Chart.yaml
apiVersion: v2
name: cache
description: Redis cache subchart used by orders-platform
type: application
version: 0.1.0
appVersion: "7.4"
EOF

cat <<'EOF' > orders-platform/charts/cache/values.yaml
enabled: true
replicaCount: 1
image:
  repository: redis
  tag: "7.4-alpine"
  pullPolicy: IfNotPresent
service:
  port: 6379
EOF
```

`condition: cache.enabled` sayesinde cache bileşeni gerektiğinde üst chart'ın
values dosyasından kapatılabilir. Subchart kendi values dosyasının varsayılan
değerlerine sahiptir; ana chart ise bunları `cache:` altında override eder.

### Adım 2: Subchart Deployment ve Service kaynaklarını yazın

```bash
cat <<'EOF' > orders-platform/charts/cache/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-cache
  labels:
    app.kubernetes.io/name: cache
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: cache
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: cache
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: redis
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: redis
              containerPort: 6379
          readinessProbe:
            tcpSocket:
              port: redis
            initialDelaySeconds: 2
            periodSeconds: 5
EOF

cat <<'EOF' > orders-platform/charts/cache/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-cache
  labels:
    app.kubernetes.io/name: cache
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: cache
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - name: redis
      port: {{ .Values.service.port }}
      targetPort: redis
EOF
```

### Adım 3: Ana uygulama kaynaklarını ve hook Job'ını yazın

```bash
cat <<'EOF' > orders-platform/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-web
  labels:
    app.kubernetes.io/name: orders-platform
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: orders-platform
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: orders-platform
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
EOF

cat <<'EOF' > orders-platform/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-web
spec:
  selector:
    app.kubernetes.io/name: orders-platform
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - name: http
      port: 80
      targetPort: 5678
EOF

cat <<'EOF' > orders-platform/templates/migration-hook.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-migration
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  backoffLimit: 1
  ttlSecondsAfterFinished: 300
  template:
    metadata:
      labels:
        app.kubernetes.io/name: migration-hook
    spec:
      restartPolicy: Never
      containers:
        - name: migration-check
          image: busybox:1.36.1
          command: ["sh", "-c", "echo migration-check completed for {{ .Release.Name }}; sleep 2"]
EOF
```

Hook, ana Deployment kaynaklarına kalıcı olarak eklenmez. Helm release
kurulmadan veya güncellenmeden hemen önce Job olarak çalışır ve başarıyla
tamamlanınca silinir. `hook-weight` değeri, birden fazla hook olduğunda çalışma
sırasını belirlemek için kullanılır.

### Adım 4: Dependency'yi indirip chart'ı doğrulayın

```bash
helm dependency build orders-platform
helm dependency list orders-platform
helm lint orders-platform
helm template orders-platform orders-platform > rendered.yaml
grep -E '^kind: (Deployment|Service|Job)$' rendered.yaml
```

Dependency listesinde `cache 0.1.0` görünmeli; lint başarılı olmalı ve render
çıktısında ana uygulama, Redis Service/Deployment ve migration Job bulunmalıdır.

### Adım 5: Release'i cluster'a kurun

```bash
helm upgrade --install orders-prod orders-platform \
  --namespace orders \
  --create-namespace \
  --wait \
  --timeout 180s

kubectl rollout status deployment/orders-prod-web -n orders --timeout=180s
kubectl rollout status deployment/orders-prod-cache -n orders --timeout=180s
kubectl get pods,service,job -n orders
kubectl logs job/orders-prod-migration -n orders
```

Migration Job `Complete`, web ve cache Pod'ları `Running/Ready` olmalıdır.

### Adım 6: Ana uygulamayı ve dependency'yi gerçek runtime ile kontrol edin

```bash
kubectl port-forward -n orders service/orders-prod-web 8081:80 >/tmp/lab-hlm-02-port-forward.log 2>&1 &
PORT_FORWARD_PID=$!
trap 'kill "$PORT_FORWARD_PID" 2>/dev/null || true' EXIT
sleep 2
curl --fail --silent http://127.0.0.1:8081/
echo
kubectl get endpoints orders-prod-web orders-prod-cache -n orders
```

HTTP yanıtında `orders-platform release v1` görünmeli; iki Service için de
endpoint adresleri dolu olmalıdır.

### Adım 7: Upgrade sırasında hook'un tekrar çalıştığını görün

```bash
helm upgrade orders-prod orders-platform \
  --namespace orders \
  --set appText="orders-platform release v2" \
  --set replicaCount=3 \
  --wait \
  --timeout 180s

kubectl rollout status deployment/orders-prod-web -n orders --timeout=180s
kubectl get deployment orders-prod-web -n orders -o jsonpath='{.spec.replicas}{" replicas\n"}'
kubectl logs job/orders-prod-migration -n orders
curl --fail --silent http://127.0.0.1:8081/
echo
helm history orders-prod -n orders
```

Yeni yanıt `orders-platform release v2`, web Deployment replika sayısı `3`
olmalıdır. Hook delete policy nedeniyle yalnızca son başarılı migration Job'ı
kalır ve upgrade sırasında yeniden oluşturulur.

## Doğal Doğrulama ve Beklenen Sonuç

```bash
helm status orders-prod -n orders
kubectl get pods,service -n orders
kubectl get job orders-prod-migration -n orders -o jsonpath='{.status.succeeded}{" successful hook\n"}'
curl --fail --silent http://127.0.0.1:8081/
echo
```

Release `deployed`, web/cache Pod'ları hazır, hook başarı sayısı `1` ve HTTP
yanıtı `orders-platform release v2` olmalıdır.
