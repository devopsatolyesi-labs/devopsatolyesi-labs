# DevOps Atölyesi Eğitim Lab ve Proje Master Planı

Bu belge Labs portalındaki tüm içerik çalışmalarının tek yol haritasıdır ve **başka bir AI veya geliştirici devraldığında sıfır bağlam kaybıyla kaldığı yerden devam edebilmesi için** hazırlanmıştır.

Tüm lablar, mini projeler ve kurulum rehberleri **Hakan Bayraktar GitHub ve Medium portföyünden** seçilmiş, güncel sürümlere yükseltilmiş ve platform standartlarımıza uyarlanmıştır.

---

## 1. Temel Kurallar ve Standartlar (Kullanıcı Direktifleri)

Bir labın veya projenin geçerli sayılması için aşağıdaki katı kurallar **istisnasız** uygulanmalıdır:

1. **Yalnız Hakan Bayraktar Portföyü:** Yalnızca Hakan Bayraktar'ın Medium makaleleri ve GitHub repolarındaki gerçek projeler kullanılır; harici alakasız kaynaklardan içerik üretilmez.
2. **Bağımsızlık:** Her lab kendi içinde 100% bağımsızdır. Başka bir labın dosyasına veya tamamlanmış olmasına bağımlı olamaz.
3. **Standart Dizin:** Öğrenci çalışma dizini daima `~/labs/<LAB-ID>` olur. Repo içi geliştirme dizinleri öğrenci dokümanında asla yer almaz.
4. **Öğrenci Sayfası Sadeliği:** Amaç kısa ve net yazılır; `## Metadata` (Seviye, Gün, Süre, Profil vb.) blokları öğrenci lab sayfasından bütünüyle kaldırılır; bu bilgiler yalnız `training-content/catalog.json` dosyasında tutulur.
5. **İnteraktif Soru Formatı:** Her labın sonunda öğrencinin konuyu derinlemesine kavramasını sağlayan senaryo bazlı interaktif sorular bulunur. Çözümler `??? tip "💡 Çözümü Göster"` collapsible bloğu ile gizlenir, öğrenci tıklayınca açılır.
6. **Merkezi Kurulum Mimarisi (Setup Hub):** Her labın içine 150 satırlık kurulum adımı kopyalanmaz. Labın başında 2 satırlık preflight uyarısı verilir ve `portal/docs/setup/` altındaki ilgili rehbere link verilir (Örn: `[🛠️ Docker Engine Kurulum Rehberi](../../setup/docker-engine.md)`).
7. **Web / ZIP Birebir Eşitliği:** Web sayfasındaki kopyalanabilir `cat <<EOF` blokları ile indirilebilir ZIP paketi aynı kanonik `starter/` ve `scripts/` kaynaklarından üretilir (`stage-content.py`).
8. **Çözüm Güvenliği:** ZIP paketleri yalnız `README.md`, `starter/`, `scripts/` ve `images/` içerir; `solution/` dosyaları asla öğrenci ZIP'ine sızdırılmaz.
9. **Gerçek Çalışan Doğrulama:** `scripts/validate.sh` basit grep yerine temiz ortamda gerçek çalışan konteyner/servis durumunu ve HTTP yanıtlarını test eder.
10. **Güvenli Temizlik:** `scripts/cleanup.sh` ve `scripts/reset.sh` yalnız o laba ait kaynakları temizler (`docker rm -f $(docker ps -aq)` gibi yıkıcı komutlar yasaktır).
11. **Dev Projeler ZIP'e Konmaz:** Öğrenci paketlerine devasa GitHub repoları (.git, devasa bağımlılıklar) konmaz. Öğrenciler projeleri laboratuvarda adım adım (`cat <<EOF`, `git clone`, starter şablonu) inşa eder.
12. **UI ve Manuel Adımlar:** Jenkins, Argo CD, SonarQube, Grafana, Kibana gibi arayüz gerektiren bölümlerde adım adım tıklama adımları yer alır.
13. **Kaynak Referansı:** Uyarlanan her labın en altında orijinal Hakan Bayraktar kaynak bağlantısı (Medium veya GitHub) belirtilir.

---

## 2. Geliştirme ve Dağıtım İş Akışı (Her AI Bu Adımları İzler)

Yeni bir lab eklerken veya güncellerken sırasıyla:

```bash
# 1. training-content/lab-assets/<LAB-ID>/ altında starter/, solution/, scripts/ oluştur
# 2. training-content/labs/<kategori>/<LAB-ID>-....md kılavuzunu hazırla
# 3. training-content/catalog.json içine labı ve kurs modülünü kaydet
# 4. portal/docs/dayX/ altında hedef kılavuz dosyasını oluştur
# 5. portal/mkdocs.yml navigasyonuna ekle
# 6. Portal içeriğini ve ZIP paketlerini derle:
python3 portal/scripts/stage-content.py training-content portal/docs

# 7. Testleri çalıştır:
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest portal/scripts/test_stage_content.py

# 8. Checksum manifestini güncelle ve doğrula:
scripts/training-checksums.sh update
scripts/training-checksums.sh check

# 9. Git commit ve push (GitHub Actions ile Harbor + Argo CD deploy tetiklenir):
git add .
git commit -m "feat(<scope>): <açıklama>"
git push origin main
```

---

## 3. Kurulum & Altyapı Hazırlığı Durumu (`setup/`)

Tüm kurulumlar `portal/docs/setup/` altında tamamlanmış ve `portal/mkdocs.yml` navigasyonuna eklenmiştir:

| Kurulum ID | Konu | Platform | Durum |
|---|---|---|---|
| `SETUP-TOOL-01` | [Docker Engine & Compose](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/docker-engine.md) | Ubuntu / Debian / AL2023 | ✅ TAMAMLANDI |
| `SETUP-K8S-01` | [kind ile Yerel K8s Kümesi](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/kind-cluster.md) | 1 Master + 2 Worker + Ingress | ✅ TAMAMLANDI |
| `SETUP-K8S-02` | [Kubeadm Multi-Node Küme](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/kubeadm-cluster.md) | Containerd + Calico CNI | ✅ TAMAMLANDI |
| `SETUP-K8S-03` | [Çoklu Kubeconfig Yönetimi](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/kubeconfig-management.md) | Flatten, Merge, kubectx | ✅ TAMAMLANDI |
| `SETUP-K8S-04` | [Dynamic NFS StorageClass](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/nfs-storageclass.md) | NFS Server + Provisioner | ✅ TAMAMLANDI |
| `SETUP-TOOL-02` | [Jenkins Kurulumu](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/jenkins-installation.md) | Docker Compose + Helm K8s | ✅ TAMAMLANDI |
| `SETUP-TOOL-03` | [Harbor Private Registry](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/harbor-registry.md) | Self-signed TLS + Trivy | ✅ TAMAMLANDI |
| `SETUP-TOOL-04` | [Prometheus & Grafana Stack](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/prometheus-grafana.md) | Docker Compose + Helm Stack | ✅ TAMAMLANDI |
| `SETUP-TOOL-05` | [ELK Stack Merkezi Loglama](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/elk-stack.md) | Elasticsearch + Logstash + Kibana | ✅ TAMAMLANDI |
| `SETUP-TOOL-06` | [Argo CD GitOps](file:///Users/hakan/devops-workspace/devopsatolyesi-labs/portal/docs/setup/argocd-setup.md) | K8s Manifest + NodePort/UI | ✅ TAMAMLANDI |

---

## 4. Lab Kataloğu ve Detaylı İlerleme Durumu

### 🐧 Temeller (Linux & Git)

| Lab ID | Seviye | Konu & Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-LNX-01` | 100 | Linux preflight, systemd servisleri, portlar, log inceleme | [`shellscript-example`](https://github.com/hakanbayraktar/shellscript-example) | ✅ TAMAMLANDI |
| `LAB-LNX-02` | 200 | Nginx Let's Encrypt SSL/TLS & Certbot Otomatik Yenileme | [Let's Encrypt SSL Nginx](https://hbayraktar.medium.com/step-by-step-guide-install-lets-encrypt-ssl-on-nginx-amazon-linux-2023-91138089c5a9) | 🔄 YAPILACAK |
| `LAB-LNX-03` | 200 | SSH Tunneling (Port Forwarding) ile Güvenli Veritabanı | [SSH Tunnel MySQL](https://hbayraktar.medium.com/secure-access-to-mysql-port-via-ssh-tunnel-fc1d01feffb9) | 🔄 YAPILACAK |
| `LAB-GIT-01` | 100 | Git branch, commit, merge, conflict resolution, rebase | Standart | ✅ TAMAMLANDI |

---

### 🐳 Docker & Containerization

| Lab ID | Seviye | Konu & Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-DOC-01` | 100 | Container lifecycle (`run`, `ps`, `logs`, `exec`, `rm`) | [Docker Cheat Sheet](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f) | ✅ TAMAMLANDI |
| `LAB-DOC-02` | 100 | Env vars, bind mount, named volume kalıcılık testi | Docker Standardı | ✅ TAMAMLANDI |
| `LAB-DOC-03` | 100 | Python API Dockerfile, build, layer cache optimizasyonu | [`flask-monitoring`](https://github.com/hakanbayraktar/flask-monitoring) | ✅ TAMAMLANDI |
| `LAB-DOC-09` | 200 | User-Defined Docker Network, Container DNS ve iletişim | Standart | ✅ TAMAMLANDI |
| `LAB-DOC-04` | 200 | Node.js API Multi-Stage Build & Non-Root UID 10001 | [`ci-cd-docker`](https://github.com/hakanbayraktar/ci-cd-docker) | ✅ TAMAMLANDI |
| `LAB-DOC-05` | 200 | Docker Compose Multi-Tier (API, Postgres, Redis) | [`book-review-app`](https://github.com/hakanbayraktar/book-review-app) | ✅ TAMAMLANDI |
| `LAB-DOC-06` | 200 | Trivy İmaj Güvenlik Taraması & Security Gate | Trivy / Harbor | ✅ TAMAMLANDI |
| `LAB-DOC-10` | 200 | Docker İmaj, Konteyner & Volume Backup/Restore | [Docker Backup/Restore](https://hbayraktar.medium.com/backing-up-and-restoring-docker-containers-and-images-8e0b6ef5849b) | ✅ TAMAMLANDI |
| `LAB-DOC-13` | 300 | Production Compose: Extensions, Çift İzole Ağ, Profiles | Production Patterns | ✅ TAMAMLANDI |
| `LAB-DOC-07` | 200 | Java Spring Boot Multi-Stage & JVM Optimizasyonu | [`spring-boot-course`](https://github.com/hakanbayraktar/spring-boot-course) | 🔄 YAPILACAK |
| `LAB-DOC-08` | 200 | Modern React / Statik Frontend & Nginx Runtime | [`s3-landing-page`](https://github.com/hakanbayraktar/s3-landing-page) | 🔄 YAPILACAK |

---

### 🚀 CI/CD & DevSecOps (Jenkins, GitLab, GitHub Actions)

| Lab ID | Seviye | Konu & Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-JNK-01` | 100 | Jenkins Declarative Pipeline (Python/Flask Lint & Build) | [`jenkins-ci-cd-lab`](https://github.com/hakanbayraktar/jenkins-ci-cd-lab) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-JNK-02` | 200 | Jenkins ile Flask Uygulamasının Kubernetes'e Dağıtımı | [Flask to K8s with Jenkins](https://hbayraktar.medium.com/deploying-a-flask-application-with-jenkins-to-a-kubernetes-cluster-4aa7b78d5817) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-GLB-01` | 200 | GitLab CI/CD Pipeline (Multi-Stage, Artifacts, Runner) | GitLab Standardı | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-GHA-01` | 200 | GitHub Actions CI/CD (Matrix, Secrets, Image Push) | [`github-actions-demo`](https://github.com/hakanbayraktar/github-actions-demo) | 🔄 YAPILACAK |

---

### ☁️ Infrastructure as Code & AWS

| Lab ID | Seviye | Konu & Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-TF-01` | 100 | Terraform Docker Provider & State Lifecycle | Terraform Standardı | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-TF-04` | 300 | Terraform & Helm ile Merkezi Kubernetes İzleme | IaC Monitoring | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-TF-08` | 300 | Terraform ile Production AWS VPC Mimarisi | [`aws-vpc-terraform`](https://github.com/hakanbayraktar/aws-vpc-terraform) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-AWS-01` | 200 | AWS Custom VPC, Bastion Host, SG & Apache Server | [Custom VPC & Bastion](https://hbayraktar.medium.com/custom-vpc-bastion-host-apache-web-server-aws-3bea50e82280) | 🔄 YAPILACAK |

---

### ☸️ Kubernetes & GitOps

| Lab ID | Seviye | Konu & Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-K8S-01` | 100 | kind Cluster Pods, Deployments & ReplicaSets | [`kubestarter`](https://github.com/hakanbayraktar/kubestarter) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-K8S-02` | 100 | Services (ClusterIP, NodePort), ConfigMaps & Secrets | [`CKA-PREP-2025-v2`](https://github.com/hakanbayraktar/CKA-PREP-2025-v2) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-K8S-03` | 200 | Production Workloads: Probes, Resource Limits, PVC | [`CKA-Certification-Course`](https://github.com/hakanbayraktar/CKA-Certification-Course-2025) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-HLM-01` | 200 | Helm Chart Paketleme, Values Yönetimi & Release | Helm Standardı | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-ARG-01` | 200 | Python Flask Uygulamasının Argo CD ile GitOps Dağıtımı | [Deploy Flask to K8s with ArgoCD](https://hbayraktar.medium.com/deploying-a-flask-python-project-to-kubernetes-with-argocd-1363d1bd9761) | 🔄 STANDARTLAŞTIRILACAK |

---

### 📈 Observability, SRE & Incident

| Lab ID | Seviye | Konu & Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-MON-01` | 200 | Prometheus Client, Exporter, PromQL & Grafana | [`flask-monitoring`](https://github.com/hakanbayraktar/flask-monitoring) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-MON-02` | 200 | Prometheus Alertmanager Kuralları & Alarmlar | Alertmanager | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-LOG-01` | 200 | Merkezi Loglama: Nginx -> Vector -> Elasticsearch | [`devops-projects-techiescamp`](https://github.com/hakanbayraktar/devops-projects-techiescamp) | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-LOG-02` | 300 | İleri ELK Stack & Kibana Log Analizi | Enterprise Logging | 🔄 STANDARTLAŞTIRILACAK |
| `LAB-INC-01` | 300 | K8s CrashLoopBackOff, OOMKilled & RCA | [Troubleshooting Guide](https://hbayraktar.medium.com/production-troubleshooting-guide-3-container-runtime-image-troubleshooting-ee5499e3a8c3) | 🔄 STANDARTLAŞTIRILACAK |

---

### 🏆 Capstone & Mini Projeler

| Proje Kodu | Seviye | Mimari ve Kapsam | Kaynak | Durum |
|---|---|---|---|---|
| `LAB-CAP-01` | 400 | Uçtan Uca CI/CD, Harbor, kind, GitOps & İzleme Platformu | `devops-capstone-starter` | 🔄 STANDARTLAŞTIRILACAK |
| `MP-PETCLINIC-01`| 400 | Java PetClinic Jenkins ile AWS EKS Dağıtımı | [PetClinic EKS Jenkins](https://hbayraktar.medium.com/automating-deployment-of-the-java-petclinic-application-on-aws-eks-with-jenkins-a-step-by-step-1e9593e74c5c) | 🔄 EKLENECEK |
| `MP-NEWS-01` | 400 | News Summary App: GitHub Actions, Argo CD & GKE | [News Summary App](https://hbayraktar.medium.com/news-summary-app-automated-ci-cd-with-github-actions-argocd-gke-c90e5575235b) | 🔄 EKLENECEK |
| `MP-ECS-01` | 400 | Flask Uygulaması GHA ile AWS ECS Fargate Dağıtımı | [Flask AWS ECS GHA](https://hbayraktar.medium.com/automating-deployment-of-a-flask-application-to-aws-ecs-with-github-actions-c256192eb8ad) | 🔄 EKLENECEK |
