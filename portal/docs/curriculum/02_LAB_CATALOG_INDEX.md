# 02 — GENEL LAB VE CHALLENGE KATALOĞU İNDEKSİ

Bu doküman, 5 günlük DevOps Practitioner eğitimi için tasarlanmış **75 adet** uygulama ve challenge labının tam indeksini içerir. Lablar **CORE** (Temel), **PRACTITIONER** (Uygulayıcı/Üretim Standartları) ve **CHALLENGE** (İleri Düzey / Hızlı Sınıf) seviyelerine dengeli biçimde dağıtılmıştır.

---

## 1. Lab Dağılım Özeti

| Teknoloji Alanı | Kod | CORE | PRACTITIONER | CHALLENGE | Toplam |
|---|---|---:|---:|---:|---:|
| **Linux & Git Temelleri** | LNX / GIT | 4 | 2 | 2 | **8** |
| **Docker & Konteyner Mühendisliği** | DOC | 4 | 5 | 3 | **12** |
| **Jenkins CI & Güvenlik/Kalite** | JNK | 3 | 4 | 2 | **9** |
| **GitLab CI/CD & Otomasyon** | GLB | 3 | 4 | 2 | **9** |
| **Terraform (Yerel & Bulut Sağlayıcılar)** | TF | 2 | 4 | 2 | **8** |
| **Kubernetes (kind & İş Yükleri)** | K8S | 4 | 5 | 3 | **12** |
| **Helm ile Paket Yönetimi** | HLM | 2 | 2 | 1 | **5** |
| **Argo CD ile GitOps Dağıtımı** | ARG | 2 | 3 | 1 | **6** |
| **Metrik Gözlemlenebilirliği (Prometheus & Grafana)** | MON | 2 | 3 | 1 | **6** |
| **Merkezi Loglama (Elasticsearch & Kibana)** | LOG | 2 | 2 | 1 | **5** |
| **DevSecOps & Olay Yönetimi (War Room)** | SEC / INC | 1 | 3 | 2 | **6** |
| **TOPLAM** | | **29** | **37** | **20** | **86** |

---

## 2. Detaylı Lab Listesi

### 2.0. Ortam Kurulumu & Temel Hazırlık (ENV)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-ENV-00` | **Ubuntu Server 24.04 LTS DevOps Ortamı Kurulumu ve Doğrulama** | FOUNDATION | Ön Hazırlık | 90 dk | `docker` | Sıfırdan adım adım manuel DevOps araçları kurulumu, profil yönetimi, smoke testler ve ortam doğrulama. |

### 2.1. Linux & Git Temelleri (LNX / GIT)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-LNX-01` | **Linux Preflight & Systemd Service Inspection** | CORE | Gün 1 | 30 dk | `docker` | Systemd servisleri, port kontrolü (`ss`, `lsof`), process analizi, disk/RAM kaynak kontrolü. |
| `LAB-LNX-02` | **Linux User, Group & Permission Hardening** | PRACTITIONER | Gün 1 | 30 dk | `docker` | Non-root servis kullanıcısı oluşturma, `sudoers` least privilege, dosya izinleri (`chmod`, `chown`). |
| `LAB-LNX-03` | **Linux Bash Scripting for DevOps Automation** | CORE | Gün 1 | 30 dk | `docker` | Hata yakalama (`set -euo pipefail`), ortam değişkenleri, `curl`, `jq` ile JSON parse etme. |
| `LAB-LNX-04` | **System Resource Limits, cgroups & OOM Investigation** | CHALLENGE | Gün 1 | 45 dk | `docker` | `/sys/fs/cgroup`, `ulimit`, `systemd-run` ile kaynak kısıtlama ve OOM killer tetikleme. |
| `LAB-GIT-01` | **Git Workflow, Branching & Conflict Resolution** | CORE | Gün 1 | 45 dk | `docker` | Feature branch, pull request / merge request mantığı, merge conflict çözümü, rebase temelleri. |
| `LAB-GIT-02` | **Git Advanced: Interactive Rebase, Bisect & Cherry-Pick** | PRACTITIONER | Gün 1 | 30 dk | `docker` | Geçmiş temizleme (`rebase -i`), hata tespit otomasyonu (`git bisect`), seçici commit aktarımı. |
| `LAB-GIT-03` | **Git Hooks & Pre-Commit Linting/Security Automation** | CHALLENGE | Gün 1 | 30 dk | `docker` | Pre-commit hook ile commit öncesi secret taraması (gitleaks) ve linter çalıştırma. |
| `LAB-GIT-04` | **Git Submodules & Monorepo Multi-Directory Management** | PRACTITIONER | Gün 1 | 30 dk | `docker` | Monorepo ve multirepo yaklaşımları, path tabanlı değişiklik izleme. |

---

### 2.2. Docker & Konteyner Mühendisliği (DOC)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-DOC-01` | **Docker Engine Verification, First Container & Port Mapping** | CORE | Gün 1 | 30 dk | `docker` | `docker run`, `-p` port mapping, `-d` daemon, `docker logs`, `docker ps`, temel komut seti. |
| `LAB-DOC-02` | **Container Lifecycle, Exec, Env Vars & Volume Persistence** | CORE | Gün 1 | 40 dk | `docker` | Ephemeral vs persistent depolama, Named Volume, Bind Mount, `docker exec`, environment vars. |
| `LAB-DOC-03` | **Docker Image Minimization & Registry Publishing (Public/Private)** | CORE | Gün 2 | 60 dk | `docker` | Şişkin imaj anti-patterni (1.28 GB), multi-stage küçültme (48 MB), Harbor ve Docker Hub (Public/Private) push. |
| `LAB-DOC-04` | **Multi-Stage Build, Non-Root Users & Image Hardening** | PRACTITIONER | Gün 2 | 60 dk | `docker` | Python/Node/Java multi-stage build, non-root user (`UID 10001`), gereksiz build araçlarını atma. |
| `LAB-DOC-05` | **Multi-Container Orchestration with Compose & Healthchecks** | PRACTITIONER | Gün 2 | 60 dk | `docker` | `compose.yaml`, API + PostgreSQL + Redis, `depends_on: condition: service_healthy`, bridge ağları. |
| `LAB-DOC-06` | **Container Security: Trivy Scanning & Harbor Registry Push** | PRACTITIONER | Gün 2 | 60 dk | `docker` | Trivy ile CVE taraması, Harbor'da proje açma, Docker login, tagleme ve güvenli push işlemi. |
| `LAB-DOC-07` | **Distroless Images & Container Minimization** | CHALLENGE | Gün 2 | 45 dk | `docker` | Google Distroless tabanlı sıfır-shell imaj üretimi, CVE sayısını sıfıra indirme. |
| `LAB-DOC-08` | **Software Bill of Materials (SBOM) Generation with Syft** | CHALLENGE | Gün 2 | 30 dk | `docker` | Konteyner imajından SPDX/CycloneDX formatında SBOM çıkarma, bağımlılık denetimi. |
| `LAB-DOC-09` | **Docker Network Troubleshooting & Custom Bridge Isolation** | PRACTITIONER | Gün 2 | 30 dk | `docker` | DNS resolution (`embedded DNS`), custom bridge vs default bridge, network disconnect/connect. |
| `LAB-DOC-10` | **Docker Resource Constraints (CPU/Memory Limits) & OOM** | PRACTITIONER | Gün 2 | 30 dk | `docker` | `--memory`, `--cpus`, `--memory-swap` kısıtları, `docker stats`, Exit Code 137 (OOM) analizi. |
| `LAB-DOC-11` | **Read-Only Root Filesystem & Tmpfs Mounts** | CHALLENGE | Gün 2 | 30 dk | `docker` | `--read-only` rootfs ile immutable container çalıştırma, `/tmp` için tmpfs mount kullanımı. |
| `LAB-DOC-12` | **Local Private Registry Setup with Authentication & TLS** | CORE | Gün 2 | 30 dk | `docker` | Basit yerel Docker registry (`registry:2`) kurulumu, basic auth ve certs konfigürasyonu. |
| `LAB-DOC-13` | **Enterprise Docker Compose Patterns: Overrides, Profiles & Tiered Networks** | PRACTITIONER | Gün 2 | 60 dk | `docker` | Çok dosyalı override mimarisi, YAML uzantıları (anchors), sıfır güven iç ağlar ve profiller. |

---

### 2.3. Jenkins CI & Güvenlik/Kalite (JNK)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-JNK-01` | **Jenkins Declarative Pipeline: Git Checkout, Build & Test** | CORE | Gün 3 | 45 dk | `secure-ci` | `Jenkinsfile` pipeline sintaksı, Docker agent, stage/steps, unit test koşumu, JUnit raporlama. |
| `LAB-JNK-02` | **Jenkins Secure Pipeline: SonarQube Gate, Trivy & Harbor** | PRACTITIONER | Gün 3 | 60 dk | `secure-ci` | SonarQube Scanner, `waitForQualityGate()`, Trivy scan, Harbor credential binding & push. |
| `LAB-JNK-03` | **Jenkins Credentials Management & Secret Masking** | CORE | Gün 3 | 30 dk | `secure-ci` | Username/Password, Secret Text, SSH Key yönetimi, loglarda şifre maskeleme testleri. |
| `LAB-JNK-04` | **Jenkins Pipeline Parameters, Environment Vars & Timestamps** | CORE | Gün 3 | 30 dk | `secure-ci` | `parameters { string, boolean, choice }`, `environment` blokları, build zaman damgaları. |
| `LAB-JNK-05` | **Jenkins Parallel Execution & Stage Retry/Timeout Handling** | PRACTITIONER | Gün 3 | 45 dk | `secure-ci` | `parallel` test koşumu, `timeout(time: 5, unit: 'MINUTES')`, `retry(3)`, `post { failure, always }`. |
| `LAB-JNK-06` | **Jenkins Multibranch Pipeline & Webhook Triggers** | PRACTITIONER | Gün 3 | 45 dk | `secure-ci` | Git branch keşfi, otomatik PR/MR buildleri, yerel webhook simülasyonu. |
| `LAB-JNK-07` | **Jenkins Shared Library for Reusable Pipeline Steps** | CHALLENGE | Gün 3 | 45 dk | `secure-ci` | Groovy tabanlı Shared Library yazımı, global standard CI fonksiyonları (`standardBuild.groovy`). |
| `LAB-JNK-08` | **Jenkins Artifact Archiving & Test Trend Reporting** | PRACTITIONER | Gün 3 | 30 dk | `secure-ci` | `archiveArtifacts`, coverage raporları, test sonuç trend grafiklerinin oluşturulması. |
| `LAB-JNK-09` | **Jenkins Agent Failure & Docker-in-Docker Debugging** | CHALLENGE | Gün 3 | 45 dk | `secure-ci` | Docker socket izin hatası, agent crash durumları ve pipeline log debug teknikleri. |

---

### 2.4. GitLab CI/CD & Otomasyon (GLB)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-GLB-01` | **GitLab CI/CD Fundamentals: Stages, Jobs & Artifacts** | CORE | Gün 3 | 45 dk | `gitlab-ci` | `.gitlab-ci.yml` sintaksı, stages, jobs, `artifacts: paths/expire_in`, job logları. |
| `LAB-GLB-02` | **GitLab Runner Configuration: Docker Executor & Socket Bind** | PRACTITIONER | Gün 3 | 45 dk | `gitlab-ci` | `gitlab-runner register`, Docker executor, `/var/run/docker.sock` bağlama, runner tags. |
| `LAB-GLB-03` | **GitLab CI Dependency Caching vs Artifacts** | CORE | Gün 3 | 30 dk | `gitlab-ci` | `cache: paths/key` (node_modules, maven repo) ile build hızlandırma, cache vs artifact farkı. |
| `LAB-GLB-04` | **GitLab CI Secure Pipeline: SonarQube & Harbor Integration** | PRACTITIONER | Gün 3 | 60 dk | `gitlab-ci` | CI/CD variables (Protected/Masked), SonarQube scanner CLI, Harbor imaj yükleme. |
| `LAB-GLB-05` | **GitLab CI Advanced Flow: Rules, Needs (DAG) & Environments** | PRACTITIONER | Gün 3 | 45 dk | `gitlab-ci` | `rules: if`, `needs` ile sırasız yönlü graf (DAG) hızlandırması, staging/prod ortamları. |
| `LAB-GLB-06` | **GitLab CI Manual Approval Gates & Rollback Jobs** | PRACTITIONER | Gün 3 | 30 dk | `gitlab-ci` | `when: manual` ile üretime onaylı dağıtım, tek tıkla geri alma (rollback) işleri. |
| `LAB-GLB-07` | **GitLab CI Security Templates & Trivy Container Scanning** | CHALLENGE | Gün 3 | 45 dk | `gitlab-ci` | GitLab Security Dashboard formatında JSON rapor çıkarma, pipeline blocker kuralları. |
| `LAB-GLB-08` | **GitLab CI Matrix Builds & Multi-Architecture Testing** | CHALLENGE | Gün 3 | 30 dk | `gitlab-ci` | `parallel: matrix` ile birden fazla Node/Python/Java versiyonunda paralel test. |
| `LAB-GLB-09` | **GitLab CI CI-Lint & Local Simulation with gitlab-ci-local** | CORE | Gün 3 | 30 dk | `gitlab-ci` | Pipeline konfigürasyonunu CI lint API ile doğrulama, yerel test yöntemleri. |

---

### 2.5. Terraform ile Kod Olarak Altyapı (TF)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-TF-01` | **Terraform Fundamentals: Docker Provider & State Lifecycle** | CORE | Gün 3 | 45 dk | `docker` | `init`, `validate`, `fmt`, `plan`, `apply`, `destroy`, `terraform.tfstate`, state kilidi. |
| `LAB-TF-02` | **Terraform Variables, Outputs, Locals & Data Sources** | CORE | Gün 4 | 40 dk | `docker` | `variables.tf`, `terraform.tfvars`, `locals`, `outputs.tf`, veri kaynakları (`data`). |
| `LAB-TF-03` | **Terraform Reusable Modules: Multi-Container Application** | PRACTITIONER | Gün 4 | 45 dk | `docker` | Modül mimarisi (`modules/app`), girdi/çıktı yönetimi, DRY prensibi. |
| `LAB-TF-04` | **Terraform & Helm ile Merkezi Kubernetes İzleme (Centralized Monitoring)** | PRACTITIONER | Gün 4 | 60 dk | `kubernetes` | Terraform ile kind üzerine Prometheus, Grafana ve ServiceMonitor yığınının deklaratif dağıtımı. |
| `LAB-TF-05` | **Terraform State Drift Detection & Resource Import** | PRACTITIONER | Gün 4 | 45 dk | `docker` | Manuel yapılan değişikliği yakalama (`drift`), `terraform import` ile kaynağı koda geçirme. |
| `LAB-TF-06` | **Terraform Resource Lifecycle Rules & Target Apply** | CHALLENGE | Gün 4 | 30 dk | `docker` | `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `-target` parametresi. |
| `LAB-TF-07` | **Terraform Security Scanning with tfsec & Checkov** | CHALLENGE | Gün 4 | 30 dk | `docker` | Altyapı kodunda güvenlik açığı, şifrelenmemiş secret ve risk taraması. |
| `LAB-TF-08` | **AWS Multi-AZ VPC with Public/Private Subnets & NAT Gateway** | PRACTITIONER | Gün 4 | 60-75 dk | `docker` / `aws` | Bryant Son referans mimarisi: Multi-AZ VPC, IGW, EIP, NAT Gateway, Public/Private Route Tables, Bastion Jump Host ve uçtan uca ağ izolasyon doğrulaması. |

---

### 2.6. Kubernetes (kind & İş Yükleri) (K8S)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-K8S-01` | **kind Multi-Node Cluster Setup & kubectl Preflight** | CORE | Gün 4 | 45 dk | `kubernetes` | `kind-config.yaml` (1 control-plane, 2 worker), `kubectl get nodes`, cluster-info, context. |
| `LAB-K8S-02` | **Pods, ReplicaSets & Declarative Deployments** | CORE | Gün 4 | 45 dk | `kubernetes` | Pod manifesti, label & selectors, ReplicaSet self-healing, Deployment scaling. |
| `LAB-K8S-03` | **Kubernetes Networking: ClusterIP, NodePort & Headless Service** | CORE | Gün 4 | 45 dk | `kubernetes` | Servis keşfi, CoreDNS, Kube-Proxy, `curl` ile podlar arası iletişim testi. |
| `LAB-K8S-04` | **Application Config: Namespaces, ConfigMaps & Secrets** | CORE | Gün 4 | 40 dk | `kubernetes` | İzolasyon (Namespace), Env/Volume olarak ConfigMap bağlama, Opaque Secret yönetimi. |
| `LAB-K8S-05` | **Production Workloads: Resource Requests, Limits & QoS Classes** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | CPU/Memory requests & limits, Guaranteed/Burstable/BestEffort QoS sınıfları. |
| `LAB-K8S-06` | **Health Probes: Liveness, Readiness & Startup Probes** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | HTTP/TCP/Exec probları, unhealthy pod yeniden başlatma, trafikte kesinti önleme. |
| `LAB-K8S-07` | **Zero-Downtime Rollouts, RollingUpdate Strategy & Rollback** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | `maxSurge`, `maxUnavailable`, `kubectl rollout status`, `kubectl rollout undo`. |
| `LAB-K8S-08` | **Persistent Storage: PersistentVolume (PV), PVC & StorageClass** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | Local-path storage class, dinamik provisioning, Pod yeniden başlasa da veri kalıcılığı. |
| `LAB-K8S-09` | **Ingress Controller (NGINX) & Ingress Routing Rules** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | kind ingress node port mapping, NGINX Ingress Controller, path-based routing. |
| `LAB-K8S-10` | **Horizontal Pod Autoscaler (HPA) & Metrics Server** | CHALLENGE | Gün 4 | 45 dk | `kubernetes` | Metrics-server kurulumu, CPU/Memory bazlı otomatik ölçekleme, load test (`hey`/`wrk`). |
| `LAB-K8S-11` | **Kubernetes Security: RBAC (Role, ClusterRole, Binding)** | CHALLENGE | Gün 4 | 45 dk | `kubernetes` | ServiceAccount oluşturma, Least Privilege Role/RoleBinding, `kubectl auth can-i`. |
| `LAB-K8S-12` | **NetworkPolicies: Microservice Traffic Isolation & Zero Trust** | CHALLENGE | Gün 4 | 45 dk | `kubernetes` | Podlar arası varsayılan reddetme (`default-deny`), sadece yetkili ingress/egress izni. |

---

### 2.7. Helm ile Paket Yönetimi (HLM)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-HLM-01` | **Helm Fundamentals: Chart Structure & Release Lifecycle** | CORE | Gün 4 | 45 dk | `kubernetes` | `helm create`, `Chart.yaml`, `values.yaml`, `helm install/upgrade/status/uninstall`. |
| `LAB-HLM-02` | **Customizing Values & Environment Overrides (Dev vs Prod)** | CORE | Gün 4 | 30 dk | `kubernetes` | `values-dev.yaml` vs `values-prod.yaml`, `--set` parametresi, konfigürasyon ayrımı. |
| `LAB-HLM-03` | **Advanced Helm Templating: Functions, Pipelines, Flow Control** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | `if/else`, `range`, `with`, `quote`, `default`, `nindent`, helper şablonları (`_helpers.tpl`). |
| `LAB-HLM-04` | **Helm Chart Dependencies & Subcharts** | PRACTITIONER | Gün 4 | 40 dk | `kubernetes` | `dependencies` bloğu ile PostgreSQL subchart ekleme, `helm dependency update`. |
| `LAB-HLM-05` | **Helm Chart Testing, Linting & OCI Registry Push (Harbor)** | CHALLENGE | Gün 4 | 30 dk | `kubernetes` | `helm lint`, `helm test`, Helm chart'ı OCI paketi olarak Harbor'a push etme. |

---

### 2.8. GitOps & Argo CD (ARG)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-ARG-01` | **Argo CD Setup, CLI Authentication & First Application** | CORE | Gün 4 | 45 dk | `kubernetes` | Argo CD kind kurulumu, initial password, CLI login, Web UI, GitOps repo bağlama. |
| `LAB-ARG-02` | **Declarative GitOps Sync, Automated Sync & Self-Healing** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | `syncPolicy: automated (prune: true, selfHeal: true)`, repo'daki değişikliğin yansıması. |
| `LAB-ARG-03` | **GitOps Drift Detection & OutOfSync Resolution** | PRACTITIONER | Gün 4 | 30 dk | `kubernetes` | Cluster'da manuel yapılan değişikliği tespit etme, Argo CD ile otomatik düzeltme. |
| `LAB-ARG-04` | **GitOps Rollback Strategy via Git Revert** | PRACTITIONER | Gün 4 | 30 dk | `kubernetes` | Hatalı sürümün Git üzerinden `git revert` ile güvenli geri alınması. |
| `LAB-ARG-05` | **Argo CD Application-in-Application (App of Apps Pattern)** | CHALLENGE | Gün 4 | 45 dk | `kubernetes` | Tek bir kök uygulama ile tüm mikroservis ve altyapı bileşenlerini orkestre etme. |
| `LAB-ARG-06` | **Argo CD Multi-Environment (Dev/Staging/Prod) with Kustomize** | PRACTITIONER | Gün 4 | 45 dk | `kubernetes` | Kustomize overlays ile ortam bazlı konfigürasyon ve Argo CD senkronizasyonu. |

---

### 2.9. Metrik Gözlemlenebilirliği (Prometheus & Grafana) (MON)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-MON-01` | **Prometheus Architecture, Scrape Targets & PromQL Basics** | CORE | Gün 5 | 45 dk | `monitoring` | `prometheus.yml`, scrape_configs, static_configs, `rate()`, `increase()`, `sum()`. |
| `LAB-MON-02` | **Node Exporter & System Resource Monitoring** | CORE | Gün 5 | 30 dk | `monitoring` | Linux CPU, RAM, Disk I/O ve Network metriklerinin toplanması ve PromQL ile analizi. |
| `LAB-MON-03` | **Application Metrics: FastAPI / Spring Boot Actuator Scraping** | PRACTITIONER | Gün 5 | 45 dk | `monitoring` | `/metrics` ve `/actuator/prometheus` endpointleri, HTTP latency, RPS, Error rate metrikleri. |
| `LAB-MON-04` | **Grafana Dashboard Creation: The 4 Golden Signals** | PRACTITIONER | Gün 5 | 60 dk | `monitoring` | Data source bağlama, Latency, Traffic, Errors, Saturation panelleri, Variables/Filters. |
| `LAB-MON-05` | **Alertmanager Rules: High Latency & Pod Crash Alerts** | PRACTITIONER | Gün 5 | 45 dk | `monitoring` | `alert.rules.yml`, `for: 1m`, severity labels, alert bildirim rotası. |
| `LAB-MON-06` | **Prometheus ServiceMonitor in Kubernetes (kube-prometheus-stack)** | CHALLENGE | Gün 5 | 45 dk | `monitoring` | CRD tabanlı dinamik hedef keşfi (`ServiceMonitor`), Prometheus Operator mantığı. |

---

### 2.10. Merkezi Loglama (Elasticsearch & Kibana) (LOG)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-LOG-01` | **2026 ELK: Nginx Loglarını Uçtan Uca Merkezileştirme** | PRACTITIONER | Gün 5 | 75 dk | `logging` | Filebeat, gerçek Nginx combined logları, Logstash Grok/PQ/DLQ, Elasticsearch ILM, Kibana Discover ve KQL. |
| `LAB-LOG-02` | **İleri ELK Gözlemlenebilirliği: Linux, Docker, Kubernetes, GeoMap ve Canvas** | CHALLENGE | Gün 5 | 150 dk | `logging` | Vector ile Linux/Docker/Kubernetes logları, Filebeat Nginx GeoIP, Metricbeat CPU/RAM, Lens dashboard, Maps ve Canvas; tamamen manuel kurulum. |
| `LAB-LOG-03` | **FluentBit / Vector Log Shipper Configuration** | PRACTITIONER | Gün 5 | 45 dk | `logging` | Docker/K8s log dosyalarını okuma, JSON parse etme, Elasticsearch'e stream etme. |
| `LAB-LOG-04` | **Kibana Data Views, Discover & Error Analysis Dashboards** | PRACTITIONER | Gün 5 | 45 dk | `logging` | Kibana Data View oluşturma, KQL filtreleme (`level: "ERROR"`), hata oranı panelleri. |
| `LAB-LOG-05` | **Correlating Logs with Distributed Trace IDs** | CHALLENGE | Gün 5 | 30 dk | `logging` | Log içerisindeki `trace_id` üzerinden ilgili HTTP isteğinin tüm yaşam döngüsünü filtreleme. |

---

### 2.11. DevSecOps & Olay Yönetimi (SEC / INC)
| Lab ID | Lab Adı | Seviye | Gün | Süre | Profil | Açıklama |
|---|---|---|---|---|---|---|
| `LAB-SEC-01` | **Secrets Scanning in Git with Gitleaks & TruffleHog** | CORE | Gün 3 | 30 dk | `docker` | Commit geçmişinde sızdırılmış API key, SSH key ve DB şifresi tespiti ve temizlenmesi. |
| `LAB-SEC-02` | **Container Base Image Hardening & CVE Remediation** | PRACTITIONER | Gün 2 | 45 dk | `docker` | Savunmasız base image'ı (`node:14`) güvenli alpine/distroless ile değiştirip CVE'leri sıfırlama. |
| `LAB-SEC-03` | **Kubernetes SecurityContext & Least Privilege Enforcement** | PRACTITIONER | Gün 4 | 40 dk | `kubernetes` | `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`. |
| `LAB-INC-01` | **War Room: Kubernetes CrashLoopBackOff & Misconfiguration** | PRACTITIONER | Gün 5 | 45 dk | `kubernetes` | Yanlış DB bağlantı parametresi kaynaklı crash teşhisi, logs/describe ile hızlı tamir. |
| `LAB-INC-02` | **War Room: ImagePullBackOff & Registry Auth Failure** | PRACTITIONER | Gün 5 | 30 dk | `kubernetes` | Eksik `imagePullSecrets` veya yanlış tag hatasının teşhisi ve çözümü. |
| `LAB-INC-03` | **War Room: Memory Leak, OOMKilled (Exit 137) & Postmortem** | CHALLENGE | Gün 5 | 45 dk | `kubernetes` | Kasıtlı bellek sızıntısı yaratan konteynerin OOM durumunu inceleme, limit artırma ve postmortem. |
