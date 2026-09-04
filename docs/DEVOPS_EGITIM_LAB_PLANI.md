# DevOps Atölyesi Eğitim Lab ve Proje Master Planı

Bu belge Labs portalındaki tüm içerik çalışmalarının tek yol haritasıdır. Tüm
kaynaklar **Hakan Bayraktar GitHub ve Medium portföyünden** seçilmiş, güncel
sürümlere yükseltilmiş ve eğitim standartlarımıza uyarlanmıştır.

Öğrenci navigasyonu konu ve seviye bazlıdır; lablar günlere göre gösterilmez.

---

## 1. Lab ve Proje İçerik Standartları

Her yayınlanmış lab aşağıdaki kuralları sağlamadan **hazır** sayılmaz:

1. **Bağımsızlık:** Başka bir labın dosyasına veya tamamlanmış olmasına bağımlı olmaz.
2. **Standart Dizin:** Standart çalışma dizini `~/labs/<LAB-ID>` olur. Repo içi geliştirme dizinleri öğrenci dokümanında yer almaz.
3. **Öğrenci Sayfası Sadeliği:** Amaç kısa yazılır; `## Metadata` (Seviye, Gün, Süre, Profil vb.) öğrenci lab sayfasından bütünüyle kaldırılır; bu bilgiler yalnız `catalog.json` dosyasında tutulur.
4. **Ön Koşul Kontrolü:** Gerekli araçlar ve ön kontrol komutları labın başında yer alır.
5. **Web/ZIP Birebir Eşitliği:** Web sayfasındaki kopyalanabilir `cat <<EOF` blokları ile indirilebilir ZIP paketi aynı kanonik `starter/` ve `scripts/` kaynaklarından üretilir.
6. **Çözüm Güvenliği:** ZIP paketleri yalnız `README.md`, `starter/`, `scripts/` ve `images/` içerir; `solution/` içermez.
7. **Gerçek Doğrulama:** `scripts/validate.sh` basit grep yerine temiz ortamda gerçek çalışan konteyner/servis durumunu ve HTTP yanıtlarını test eder.
8. **Güvenli Temizlik:** `scripts/cleanup.sh` ve `scripts/reset.sh` yalnız o laba ait kaynakları temizler.
9. **UI ve Manuel Adımlar:** Jenkins, Argo CD, SonarQube, Grafana, Kibana ve AWS gibi görsel/UI arayüzü gerektiren bölümlerde adım adım tıklama adımları ve mimari diyagramlar yer alır.
10. **Kaynak Referansı:** Uyarlanan her labın en altında orijinal Hakan Bayraktar kaynak bağlantısı belirtilir.

---

## 2. Kalite Kapıları

Bir labın durumu yalnız şu sırayla ilerler:

- `draft`: içerik ve dosyalar hazırlanıyor.
- `content-ready`: web/ZIP eşitliği ve statik kontroller geçti.
- `runtime-tested`: temiz Ubuntu lab makinesinde kurulum, uygulama, doğrulama ve temizlik geçti.
- `published`: doğru eğitim grubuyla canlı portal testi geçti.

---

## 3. Kategorilere ve Seviyelere Göre Lab Kataloğu

### 🐧 Temeller (Linux & Git & Güvenlik)

| Lab ID | Seviye | Konu & Kapsam | Kaynak Makale / Proje | Paketler |
|---|---|---|---|---|
| `LAB-LNX-01` | 100 | Linux preflight, systemd servisleri, süreçler, portlar, log inceleme ve cgroups | [`shellscript-example`](https://github.com/hakanbayraktar/shellscript-example) | `devops-practitioner-5-day` |
| `LAB-LNX-02` | 200 | Nginx üzerinde Let's Encrypt SSL/TLS Sertifikası Kurulumu ve Otomatik Yenileme | [Let's Encrypt SSL on Nginx](https://hbayraktar.medium.com/step-by-step-guide-install-lets-encrypt-ssl-on-nginx-amazon-linux-2023-91138089c5a9) | `devops-practitioner-5-day` |
| `LAB-LNX-03` | 200 | SSH Tunneling (Local/Remote Port Forwarding) ile Güvenli Veritabanı Erişimi | [Secure Access via SSH Tunnel](https://hbayraktar.medium.com/secure-access-to-mysql-port-via-ssh-tunnel-fc1d01feffb9) | `devops-practitioner-5-day` |
| `LAB-GIT-01` | 100 | Git branch, commit, merge, conflict resolution, rebase ve tag yönetimi | Temel Git Standardı | `devops-practitioner-5-day` |

---

### 🐳 Docker & Containerization (Eksiksiz Çekirdek ve İleri Düzey Set)

> **İnteraktif Alıştırma Formatı:** Docker temel komutları için lab sayfalarında **Soru / Senaryo** verilir; çözümler `??? tip "💡 Çözümü Göster"` gizli bloğu içinde yer alır, öğrenci tıklayınca açılır.

| Lab ID | Seviye | Konu & Kapsam | Kaynak Makale / Proje | Paketler |
|---|---|---|---|---|
| `LAB-DOC-01` | 100 | Container lifecycle: `run`, `ps`, `logs`, `inspect`, `exec`, `stop/start`, `rm` (İnteraktif gizli çözümlü alıştırmalar) | [Docker Commands Cheat Sheet](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-02` | 100 | Environment variables, bind mount, named volume ve veri kalıcılığı | Docker Storage Standardı | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-03` | 100 | Python API için Dockerfile, build, tag, port mapping ve run | [`flask-monitoring`](https://github.com/hakanbayraktar/flask-monitoring) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-04` | 200 | Node.js API, layer cache optimizasyonu, multi-stage build ve non-root güvenliği | [`ci-cd-docker`](https://github.com/hakanbayraktar/ci-cd-docker), [`jenkins-node`](https://github.com/hakanbayraktar/jenkins-node) | `devops-5-day` |
| `LAB-DOC-05` | 200 | Docker Compose ile Multi-Tier Orchestration (Frontend, API, Postgres, Redis) | [`book-review-app`](https://github.com/hakanbayraktar/book-review-app) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-06` | 200 | Trivy ile imaj güvenlik taraması ve Private Harbor Registry push/pull | DevSecOps Standardı | `devops-5-day` |
| `LAB-DOC-07` | 200 | Java Spring Boot uygulamasını multi-stage dockerize etme & JVM optimizasyonu | [`spring-boot-course`](https://github.com/hakanbayraktar/spring-boot-course), [`petclinic-java`](https://github.com/hakanbayraktar/petclinic-java) | `devops-5-day` |
| `LAB-DOC-08` | 200 | Modern React/Static frontend build ve Nginx runtime container | [`s3-landing-page`](https://github.com/hakanbayraktar/s3-landing-page) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-09` | 200 | User-defined Docker Network, Container DNS ve servisler arası iletişim | Container Networking Standardı | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-10` | 200 | Docker İmaj ve Konteyner Yedekleme / Geri Yükleme (`save`, `load`, `export`, `import`) | [Docker Backup and Restore](https://hbayraktar.medium.com/backing-up-and-restoring-docker-containers-and-images-8e0b6ef5849b) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-DOC-13` | 300 | Production Compose: Healthcheck, restart policies, resource limits ve profile | Production Patterns | `devops-5-day` |

---

### 🚀 CI/CD & DevSecOps (Jenkins, GitLab, GitHub Actions)
*(Jenkins & GitLab Web UI arayüzünden görsel adımlar ve adım adım boru hattı yönetimi)*

| Lab ID | Seviye | Konu & Kapsam | Kaynak Makale / Proje | Paketler |
|---|---|---|---|---|
| `LAB-JNK-01` | 100 | Jenkins Declarative Pipeline ile Python/Flask Test, Lint & Build | [`jenkins-ci-cd-lab`](https://github.com/hakanbayraktar/jenkins-ci-cd-lab) | `devops-practitioner-5-day` |
| `LAB-JNK-02` | 200 | Jenkins ile Flask Uygulamasının Kubernetes Kümesine Otomatik Dağıtımı | [Flask App to K8s with Jenkins](https://hbayraktar.medium.com/deploying-a-flask-application-with-jenkins-to-a-kubernetes-cluster-4aa7b78d5817) | `devops-practitioner-5-day` |
| `LAB-GLB-01` | 200 | GitLab CI/CD Pipeline (Multi-Stage, Artifacts, Runner & Caching) | GitLab Standardı | `devops-practitioner-5-day` |
| `LAB-GHA-01` | 200 | GitHub Actions CI/CD (Matrix Builds, Secrets, Image Build & Push) | [`github-actions-demo`](https://github.com/hakanbayraktar/github-actions-demo), [`github-action-simple`](https://github.com/hakanbayraktar/github-action-simple) | `devops-practitioner-5-day` |

---

### ☁️ Infrastructure as Code & AWS Bulut

| Lab ID | Seviye | Konu & Kapsam | Kaynak Makale / Proje | Paketler |
|---|---|---|---|---|
| `LAB-TF-01` | 100 | Terraform Docker Provider, Resource Declarations ve State Lifecycle | Terraform Standardı | `devops-practitioner-5-day` |
| `LAB-TF-04` | 300 | Terraform ile Helm Provider Üzerinden Kubernetes İzleme Kurulumu | IaC Monitoring | `devops-practitioner-5-day` |
| `LAB-TF-08` | 300 | Terraform ile Production AWS VPC Mimarisi (Subnets, IGW, NAT, Route Tables) | [`aws-vpc-terraform`](https://github.com/hakanbayraktar/aws-vpc-terraform) | `devops-practitioner-5-day` |
| `LAB-AWS-01` | 200 | AWS Custom VPC, Bastion Host, Security Groups ve Apache Web Server | [Custom VPC & Bastion Host](https://hbayraktar.medium.com/custom-vpc-bastion-host-apache-web-server-aws-3bea50e82280) | İleri Katalog |

---

### ☸️ Kubernetes & GitOps
*(Argo CD Web UI, Kubeconfig birleştirme, Private Registry ve Dinamik StorageClass adımları)*

| Lab ID | Seviye | Konu & Kapsam | Kaynak Makale / Proje | Paketler |
|---|---|---|---|---|
| `LAB-K8S-01` | 100 | kind Cluster Kurulumu, Pods, Deployments & ReplicaSets | [`kubestarter`](https://github.com/hakanbayraktar/kubestarter), [`kubernetes-lab`](https://github.com/hakanbayraktar/kubernetes-lab) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-K8S-02` | 100 | Kubernetes Services (ClusterIP, NodePort), ConfigMaps & Secrets | [`CKA-PREP-2025-v2`](https://github.com/hakanbayraktar/CKA-PREP-2025-v2) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-K8S-03` | 200 | Production Workloads: Probes (Liveness/Readiness), Resource Limits, Rollout & PVC | [`CKA-Certification-Course-2025`](https://github.com/hakanbayraktar/CKA-Certification-Course-2025) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-K8S-04` | 200 | Çoklu Kubeconfig Dosyalarını Tek Dosyada Birleştirme & Context Yönetimi | [Merging Kubeconfig Files](https://hbayraktar.medium.com/merging-multiple-kubeconfig-files-into-one-a-comprehensive-guide-33cb7990edfc) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-K8S-05` | 300 | Kubernetes'te Dinamik NFS Provisioning ve StorageClass Yapılandırması | [Dynamic NFS Provisioning in K8s](https://hbayraktar.medium.com/how-to-setup-dynamic-nfs-provisioning-in-a-kubernetes-cluster-cbf433b7de29) | `devops-practitioner-5-day` |
| `LAB-K8S-06` | 200 | Kubernetes Kümesinde Private Registry (Harbor/Docker Hub) `imagePullSecrets` Kullanımı | [Pull Image from Private Registry](https://hbayraktar.medium.com/how-to-pull-an-image-from-a-private-docker-registry-in-kubernetes-cluster-71239e428490) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-K8S-ADMIN-01` | 300 | Ubuntu 22.04 / 24.04 Üzerinde Kubeadm & Containerd ile Sıfırdan K8s Kümesi Kurulumu | [Install K8s Cluster on Ubuntu](https://hbayraktar.medium.com/how-to-install-kubernetes-cluster-on-ubuntu-22-04-step-by-step-guide-7dbf7e8f5f99) | İleri Katalog |
| `LAB-HLM-01` | 200 | Uygulamayı Helm Chart Olarak Paketleme, Values Yönetimi & Release | Helm Standardı | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-ARG-01` | 200 | Python Flask Uygulamasının Argo CD ile Kubernetes'e GitOps Dağıtımı & Self-Healing | [Deploy Flask to K8s with ArgoCD](https://hbayraktar.medium.com/deploying-a-flask-python-project-to-kubernetes-with-argocd-1363d1bd9761) | `devops-5-day` |

---

### 📈 Gözlemlenebilirlik (Observability), SRE & Olay Yönetimi

| Lab ID | Seviye | Konu & Kapsam | Kaynak Makale / Proje | Paketler |
|---|---|---|---|---|
| `LAB-MON-01` | 200 | Uygulama Metrikleri (Prometheus Client), Prometheus Server & Grafana Dashboards | [`flask-monitoring`](https://github.com/hakanbayraktar/flask-monitoring) | `devops-practitioner-5-day` |
| `LAB-MON-02` | 200 | Prometheus Alertmanager Kuralları, Severity & Bildirimler | Prometheus Alerting | `devops-practitioner-5-day` |
| `LAB-LOG-01` | 200 | Merkezi Loglama: Nginx Logs -> Vector/Logstash -> Elasticsearch & Kibana | [`devops-projects-techiescamp`](https://github.com/hakanbayraktar/devops-projects-techiescamp) | `devops-practitioner-5-day` |
| `LAB-LOG-02` | 300 | İleri ELK Stack & Kibana Gözlemlenebilirlik Dashboardları | Enterprise Logging | `devops-practitioner-5-day` |
| `LAB-OTEL-01` | 300 | OpenTelemetry Collector, Dağıtık İzleme (Distributed Tracing) & Tempo/Jaeger | CNCF OpenTelemetry | `devops-practitioner-5-day` |
| `LAB-INC-01` | 300 | Kubernetes Olay Müdahalesi (CrashLoopBackOff, OOMKilled) & Root Cause Analysis | [Troubleshooting Guide](https://hbayraktar.medium.com/production-troubleshooting-guide-3-container-runtime-image-troubleshooting-ee5499e3a8c3) | `devops-5-day`, `docker-k8s-2-day` |
| `LAB-AI-01` | 300 | AI Destekli Kubernetes Troubleshooting & Runbook Analizi | [`ai-assisted-devops-workshop`](https://github.com/hakanbayraktar/ai-assisted-devops-workshop) | İleri Katalog |

---

## 4. Gerçek Dünya Projeleri ve Mini Projeler

> **Önemli Kural:** Öğrenci eğitim paketlerinin (`.zip`) içine devasa GitHub projeleri doğrudan konmaz. Öğrenciler projeleri laboratuvar ortamında temiz ve adım adım (`git clone`, `cat <<EOF`, starter şablonu) uygulayarak inşa ederler.

| Proje Kodu | Seviye | Mimari ve Kapsam | Kaynak Makale / Proje |
|---|---|---|---|
| **`LAB-CAP-01`** | 400 (Capstone) | Koddan CI, Harbor, kind, GitOps ve İzlemeye Uçtan Uca Platform | `devops-capstone-starter` public GitHub şablonu |
| **`MP-PETCLINIC-01`** | 400 (Mini Proje) | Java PetClinic Uygulamasının Jenkins ile AWS EKS Kümesine Dağıtımı | [PetClinic on AWS EKS with Jenkins](https://hbayraktar.medium.com/automating-deployment-of-the-java-petclinic-application-on-aws-eks-with-jenkins-a-step-by-step-1e9593e74c5c) |
| **`MP-NEWS-01`** | 400 (Mini Proje) | News Summary App: GitHub Actions, Argo CD ve Kubernetes GitOps | [News Summary App with GitHub Actions & ArgoCD](https://hbayraktar.medium.com/news-summary-app-automated-ci-cd-with-github-actions-argocd-gke-c90e5575235b) |
| **`MP-ECS-01`** | 400 (Mini Proje) | Flask Uygulamasının GitHub Actions ile AWS ECS Fargate'e Dağıtımı | [Flask Deployment to AWS ECS with GHA](https://hbayraktar.medium.com/automating-deployment-of-a-flask-application-to-aws-ecs-with-github-actions-c256192eb8ad) |
| **`MP-RETAIL-01`** | 400 (Mini Proje) | AWS Retail Store Microservices Platform & ECS Fargate | [`retail-store-sample-app`](https://github.com/hakanbayraktar/retail-store-sample-app), [`ecs-fargate-retail-sample-production`](https://github.com/hakanbayraktar/ecs-fargate-retail-sample-production) |
| **`MP-BANK-01`** | 400 (Mini Proje) | Java Spring Boot AI Bank App Multi-Tier Microservices | [`AI-BankApp-DevOps`](https://github.com/hakanbayraktar/AI-BankApp-DevOps), [`java-spring-microservices`](https://github.com/hakanbayraktar/java-spring-microservices) |
| **`MP-MERN-01`** | 400 (Mini Proje) | MERN Stack E-Commerce Platform Containerization & Monitoring | [`MERN-AI-Ecommerce-Platform`](https://github.com/hakanbayraktar/MERN-AI-Ecommerce-Platform) |
| **`MP-BOUTIQUE-01`** | 400 (Mini Proje) | Google Online Boutique & Traefik v3 Gateway API | Google Online Boutique |
| **`MP-FINOPS-01`** | 400 (Mini Proje) | AWS FinOps & Kubernetes Cost Optimization Dashboard | [`aws-finops-dashboard`](https://github.com/hakanbayraktar/aws-finops-dashboard), [`opencost`](https://github.com/hakanbayraktar/opencost) |

---

## 5. Uygulama Sırası

1. **Docker Çekirdeği:** `LAB-DOC-01`, `02`, `03`, `09`, `05`
2. **Docker Çoklu Dil ve Güvenlik:** `LAB-DOC-04`, `06`, `07`, `08`, `10`, `13`
3. **CI/CD & DevSecOps:** `LAB-JNK-01`, `02`, `LAB-GLB-01`, `LAB-GHA-01`
4. **IaC, Kubernetes ve GitOps:** `LAB-TF-01`, `04`, `08`, `LAB-K8S-01`, `02`, `03`, `LAB-HLM-01`, `LAB-ARG-01`
5. **Observability & SRE:** `LAB-MON-01`, `02`, `LAB-LOG-01`, `02`, `LAB-OTEL-01`, `LAB-INC-01`
6. **Capstone ve Mini Projeler:** `LAB-CAP-01`, `MP-RETAIL-01`, `MP-BANK-01`, `MP-PETCLINIC-01`, `MP-MERN-01`
7. **Kabul ve Entegrasyon Testi:** Rol bazlı erişim, indirme, runtime ve temizlik doğrulamaları
