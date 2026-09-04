# 04 — OPSİYONEL, İLERİ SEVİYE & SHOW-OFF LAB HAVUZU

Bu doküman; hızlı ilerleyen sınıflar, ileri düzey öğrenciler veya eğitmenin referans platform gösterimi (SEE IT) için tasarlanmış **opsiyonel ve ileri seviye lab havuzunu** içerir.

---

## 1. Opsiyonel Lab Matrisi

| Lab ID | Teknoloji | Seviye | Hedef / Senaryo | Gereken Profil |
|---|---|---|---|---|
| `LAB-DOC-07` | Docker / Security | CHALLENGE | Google Distroless ile kabuksuz (shell-less) imaj üretimi ve CVE'leri sıfırlama | `docker` |
| `LAB-DOC-08` | Docker / SBOM | CHALLENGE | Syft & Grype ile OCI imajından SPDX/CycloneDX formatında SBOM üretimi | `docker` |
| `LAB-DOC-11` | Docker / Hardening | CHALLENGE | Salt-okunur dosya sistemi (`--read-only`) ve tmpfs mount ile konteyner çalıştırma | `docker` |
| `LAB-DOC-13` | Docker / Architecture | PRACTITIONER | Kurumsal Docker Compose Desenleri (Overrides, Profiles, Extensions & Tiered Networks) | `docker` |
| `LAB-JNK-07` | Jenkins / Groovy | CHALLENGE | Groovy ile yeniden kullanılabilir Jenkins Shared Library yazımı | `secure-ci` |
| `LAB-GLB-05` | GitLab CI | PRACTITIONER | `needs:` yönergesi ile Yönlü Döngüsüz Çizge (DAG) tabanlı ultra hızlı pipeline | `gitlab-ci` |
| `LAB-TF-04` | Terraform / K8s | PRACTITIONER | Terraform Kubernetes & Helm Provider ile kind cluster üzerine kaynak kurma | `kubernetes` |
| `LAB-TF-07` | Terraform / Security | CHALLENGE | Checkov ve tfsec ile altyapı kodlarında statik güvenlik analizi | `docker` |
| `LAB-TF-08` | Terraform / Cloud IaC | PRACTITIONER | Production AWS Multi-AZ VPC: Public/Private Subnets, NAT Gateway Egress & Bastion Host | `docker` / `aws` |
| `LAB-K8S-10` | Kubernetes / Autoscaling | CHALLENGE | Horizontal Pod Autoscaler (HPA) ve Metrics Server ile dinamik yük ölçekleme | `kubernetes` |
| `LAB-K8S-11` | Kubernetes / Security | CHALLENGE | ServiceAccount, Role ve RoleBinding ile RBAC Least Privilege denetimi | `kubernetes` |
| `LAB-K8S-12` | Kubernetes / Networking | CHALLENGE | NetworkPolicy ile podlar arası Sıfır Güven (Zero Trust) ağ izolasyonu | `kubernetes` |
| `LAB-ARG-05` | GitOps / Architecture | CHALLENGE | Argo CD App-of-Apps deseni ile tüm sistem mikroservislerini tek kökten yönetme | `kubernetes` |
| `LAB-MON-06` | Prometheus / Operator | CHALLENGE | Prometheus Operator ve `ServiceMonitor` CRD ile dinamik metrik keşfi | `monitoring` |
| `LAB-OTEL-01` | OpenTelemetry / Tracing | CHALLENGE | OpenTelemetry Collector ve Jaeger ile mikroservisler arası dağıtık izleme (tracing) | `monitoring` |

---

## 2. Seçilmiş İleri Seviye Lab Detayları

### LAB-DOC-07: Distroless Images & Container Minimization (CHALLENGE)
* **Senaryo:** Üretim imajında paket yöneticisi (`apt`, `apk`), derleyici veya kabuk (`/bin/sh`, `/bin/bash`) bulunmamalıdır.
* **Uygulama Adımları:**
  ```bash
  mkdir -p ~/devops-workspace/labs/LAB-DOC-07 && cd ~/devops-workspace/labs/LAB-DOC-07
  cat <<'EOF' > main.go
  package main
  import (
      "fmt"
      "net/http"
  )
  func main() {
      http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
          fmt.Fprintf(w, "Hello from Pure Distroless Go Binary!")
      })
      http.ListenAndServe(":8080", nil)
  }
  EOF

  cat <<'EOF' > Dockerfile
  FROM golang:1.22-alpine AS builder
  WORKDIR /build
  COPY main.go .
  RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server main.go

  FROM gcr.io/distroless/static-debian12:nonroot
  WORKDIR /
  COPY --from=builder /build/server /server
  USER nonroot:nonroot
  EXPOSE 8080
  ENTRYPOINT ["/server"]
  EOF

  docker build -t distroless-demo:latest .
  docker run -d --name distroless-test -p 8080:8080 distroless-demo:latest
  ```
* **Doğrulama:**
  ```bash
  # İmaj boyutu kontrolü (< 15 MB)
  docker images distroless-demo:latest
  # Kabuk erişimi denemesi (Engellenmelidir!)
  docker exec -it distroless-test sh || echo "DISTROLESS CONFIRMED: No shell found inside container!"
  ```

---

### LAB-DOC-13: Kurumsal Docker Compose Desenleri (PRACTITIONER)
* **Senaryo:** YAML uzantı alanları (`x-logging`, `x-app-defaults`), çok dosyalı override katmanlama (`compose.yaml`, `compose.override.yaml`, `compose.prod.yaml`), çift ağlı sıfır güven mimarisi (`gateway_net`, `data_net`), isteğe bağlı profiller (`worker`, `monitoring`, `debug`) ve katı ortam değişkeni doğrulaması.
* **Tam Doküman:** [LAB-DOC-13-docker-compose-production-patterns.md](file:///Users/hakan/devops-workspace/devops-practitioner-egitim-katalogu/outputs/labs/docker/LAB-DOC-13-docker-compose-production-patterns.md)
* **Uygulama Adımları:**
  1. `app/` mikroservis ve worker kaynak kodlarının hazırlanması (FastAPI, PostgreSQL, Redis).
  2. NGINX Ingress Gateway (`nginx.conf`) konfigürasyonu.
  3. `.env` dosyasında katı değişken doğrulaması (`${VAR:?Hata}`).
  4. `compose.yaml` (Base), `compose.override.yaml` (Dev) ve `compose.prod.yaml` (Prod) hazırlanması.
  5. `docker compose config` ile DRY anchor çözünürlüğünün testi.
  6. `docker compose up -d` ile temel yığının başlatılması ve sağlık denetimi.
  7. `docker compose --profile worker up -d` ile asenkron kuyruk tüketiminin doğrulanması.

---

### LAB-K8S-10: Horizontal Pod Autoscaler (HPA) & Load Testing (CHALLENGE)
* **Senaryo:** CPU kullanımı %50'yi aştığında pod sayısının otomatik olarak 2'den 8'e çıkması.
* **Uygulama Adımları:**
  ```bash
  # Metrics Server kurulumu (kind için insecure TLS bayrağıyla)
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
  
  # HPA Tanımlama
  cat <<'EOF' | kubectl apply -f -
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: payment-api-hpa
  spec:
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: robust-web-service
    minReplicas: 2
    maxReplicas: 8
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 50
  EOF
  ```
* **Doğrulama:**
  ```bash
  kubectl get hpa payment-api-hpa
  # Yük testi başlatıldığında TARGETS değerinin yükseldiği ve REPLICAS sayısının 8'e kadar arttığı izlenir.
  ```

---

### LAB-K8S-12: Zero Trust NetworkPolicies (CHALLENGE)
* **Senaryo:** Veritabanına sadece ve sadece `frontend-api` podundan erişilebilmesi, diğer tüm podlardan gelen trafiğin engellenmesi.
* **Uygulama Adımları:**
  ```bash
  cat <<'EOF' | kubectl apply -f -
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: db-strict-isolation
  spec:
    podSelector:
      matchLabels:
        app: postgres-db
    policyTypes:
      - Ingress
    ingress:
      - from:
          - podSelector:
              matchLabels:
                app: order-api
        ports:
          - protocol: TCP
            port: 5432
  EOF
  ```
* **Doğrulama:**
  ```bash
  # Yetkisiz poddan DB'ye erişim denenir (Timeout / Engellenmeli)
  kubectl run rogue-pod --rm -i --tty --image=busybox -- nc -zv -w 3 postgres-db 5432 || echo "ZERO TRUST SUCCESS: Unauthorized traffic blocked!"
  ```

---

### LAB-TF-04: Terraform & Helm ile Merkezi Kubernetes İzleme (PRACTITIONER)
* **Senaryo:** Terraform `helm` ve `kubernetes` sağlayıcıları ile `kube-prometheus-stack`'in bellek optimizasyonlu olarak kind kümesine dağıtılması, Prometheus, Grafana ve `ServiceMonitor` ile merkezi metrik toplama.
* **Tam Doküman:** [LAB-TF-04-terraform-helm-centralized-monitoring.md](file:///Users/hakan/devops-workspace/devops-practitioner-egitim-katalogu/outputs/labs/terraform/LAB-TF-04-terraform-helm-centralized-monitoring.md)
* **Uygulama Adımları (7 Güçlü Adım):**
  1. `providers.tf` (helm + kubernetes) ve `variables.tf` tanımlama.
  2. Düşük bellekli kind profili için `values-monitoring.yaml` optimizasyonu (12h retention, 512Mi limit).
  3. `main.tf` ile deklaratif `kubernetes_namespace` ve `helm_release` tanımı.
  4. `terraform init && terraform apply -auto-approve` icrası.
  5. `kubectl get pods -n monitoring` ile pod sağlık kontrolü.
  6. `ServiceMonitor` CRD ile örnek mikroservis metriklerinin otomatik keşfi.
  7. Grafana UI (`localhost:3000`) erişimi ve Golden Signals panellerinin incelenmesi.

---

### LAB-OTEL-01: OpenTelemetry Distributed Tracing (SHOW-OFF)
* **Senaryo:** Frontend -> API Gateway -> Order Service -> Payment Service çağrı zincirinin tek bir `trace_id` ile Jaeger arayüzünde görselleştirilmesi.
* **Eğitmen Notu:** Bu lab öğrencilere `devopsatolyesi.com/jaeger` üzerinden OpenTelemetry Astronomy Shop referans uygulaması ile canlı olarak gösterilir.
