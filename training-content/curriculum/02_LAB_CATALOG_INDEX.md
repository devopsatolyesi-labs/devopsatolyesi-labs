# 02 — DevOps Lab Kataloğu ve Zorluk Seviyeleri

DevOps Atölyesi laboratuvar kütüphanesi, katılımcıların bilgi seviyelerine ve hedeflerine göre **3 ana zorluk düzeyinde** yapılandırılmıştır.

Aşağıdaki sekmeleri kullanarak dilediğiniz seviyedeki labları listeleyebilir ve doğrudan çalışmaya başlayabilirsiniz:

=== "Tüm Lablar (65 Lab)"

    | Lab ID | Seviye | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-ENV-00` | 🟢 CORE | Ubuntu Server 24.04 DevOps Ortamı Kurulumu ve Doğrulama | ENVIRONMENT | 90 dk | `-` | [Labı Aç →](../env/LAB-ENV-00-environment-setup/) |
    | `LAB-LNX-01` | 🟢 CORE | Linux Preflight ve Systemd Servis İncelemesi | LINUX | 30 dk | `22` | [Labı Aç →](../day1/LAB-LNX-01-linux-preflight/) |
    | `LAB-GIT-01` | 🟢 CORE | Git Workflow, Branching ve Conflict Resolution | GIT | 45 dk | `-` | [Labı Aç →](../day1/LAB-GIT-01-git-workflow/) |
    | `LAB-DOC-01` | 🟢 CORE | İlk Docker Konteyneri ve Temel Komutlar | DOCKER | 35 dk | `8080` | [Labı Aç →](../day1/LAB-DOC-01-docker-first-container/) |
    | `LAB-DOC-02` | 🟢 CORE | Konteyner Yaşam Döngüsü ve Teşhis Komutları | DOCKER | 40 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-02-docker-lifecycle-diagnostics/) |
    | `LAB-DOC-03` | 🟢 CORE | Docker İmaj, Etiketleme ve Registry Yönetimi | DOCKER | 45 dk | `5000` | [Labı Aç →](../day2/LAB-DOC-03-docker-image-registry/) |
    | `LAB-DOC-04` | 🟢 CORE | Docker Volumes ve Veri Kalıcılığı | DOCKER | 45 dk | `5432` | [Labı Aç →](../day2/LAB-DOC-04-docker-volumes-persistence/) |
    | `LAB-DOC-05` | 🟢 CORE | Ortam Değişkenleri, .env ve Konfigürasyon Yönetimi | DOCKER | 35 dk | `3000` | [Labı Aç →](../day2/LAB-DOC-05-docker-env-secrets/) |
    | `LAB-DOC-06` | 🟡 PRACTITIONER | Docker Network, Port İzolasyonu ve DNS Çözümleme | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-06-docker-networks-dns/) |
    | `LAB-DOC-07` | 🟡 PRACTITIONER | İlk Dockerfile ile İmaj Oluşturma | DOCKER | 40 dk | `5000` | [Labı Aç →](../day2/LAB-DOC-07-dockerfile-basics/) |
    | `LAB-DOC-08` | 🟡 PRACTITIONER | Dockerfile Katmanları ve BuildKit Cache | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-08-dockerfile-optimization/) |
    | `LAB-DOC-09` | 🟡 PRACTITIONER | Multi-Stage Build ve Boyut Optimizasyonu | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-09-docker-multistage-build/) |
    | `LAB-DOC-10` | 🔴 ADVANCED | Docker Runtime Güvenliği ve Hardening | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-10-docker-runtime-security/) |
    | `LAB-DOC-11` | 🟡 PRACTITIONER | Java Spring Boot Konteynerleştirme ve JVM Optimizasyonu | DOCKER | 50 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-11-docker-java-spring-boot/) |
    | `LAB-DOC-12` | 🟡 PRACTITIONER | React SPA ve Nginx Frontend Container | DOCKER | 40 dk | `80` | [Labı Aç →](../day2/LAB-DOC-12-docker-react-nginx/) |
    | `LAB-DOC-13` | 🟡 PRACTITIONER | Docker Compose ile Çok Katmanlı Mimari | DOCKER | 50 dk | `80, 3000, 5432` | [Labı Aç →](../day2/LAB-DOC-13-docker-compose-multitier/) |
    | `LAB-DOC-14` | 🔴 ADVANCED | Healthcheck, Restart Policy ve Kaynak Limitleri | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-14-docker-healthcheck-limits/) |
    | `LAB-DOC-15` | 🟡 PRACTITIONER | Docker Loglama ve Gözlemlenebilirlik | DOCKER | 40 dk | `8080, 8081` | [Labı Aç →](../day2/LAB-DOC-15-docker-logging-observability/) |
    | `LAB-DOC-16` | 🟡 PRACTITIONER | Trivy Güvenlik Taraması, SBOM ve Harbor Entegrasyonu | DOCKER | 50 dk | `80, 443` | [Labı Aç →](../day2/LAB-DOC-16-trivy-harbor-integration/) |
    | `LAB-DOC-17` | 🟡 PRACTITIONER | İmaj ve Volume Yedekleme / Geri Yükleme | DOCKER | 45 dk | `5432` | [Labı Aç →](../day2/LAB-DOC-17-docker-backup-restore/) |
    | `LAB-DOC-18` | 🔴 ADVANCED | Docker Sorun Giderme ve Teşhis Senaryoları | DOCKER | 55 dk | `8080, 5432` | [Labı Aç →](../day2/LAB-DOC-18-docker-troubleshooting/) |
    | `LAB-DOC-19` | 🔴 ADVANCED | Production Docker Compose Desenleri | DOCKER | 50 dk | `80, 3000` | [Labı Aç →](../day2/LAB-DOC-19-docker-compose-production-patterns/) |
    | `LAB-DOC-20` | 🔴 ADVANCED | Docker Final Capstone Projesi: Üretim Seviyesi Mikroservis Platformu | DOCKER | 90 dk | `80, 3000, 5432, 6379` | [Labı Aç →](../day2/LAB-DOC-20-docker-capstone/) |
    | `LAB-JEN-01` | 🟢 CORE | Docker Compose ile Jenkins Kurulumu ve Nginx Reverse Proxy | JENKINS | 40 dk | `8080, 8443` | [Labı Aç →](../day3/LAB-JEN-01-docker-compose-setup/) |
    | `LAB-JEN-02` | 🟢 CORE | Jenkins İlk Yapılandırma, Yönetici Hesabı ve Eklenti Yönetimi | JENKINS | 35 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-02-initial-setup-plugins/) |
    | `LAB-JEN-03` | 🟢 CORE | İlk Freestyle Build Job ve Workspace Temelleri | JENKINS | 35 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-03-first-freestyle-job/) |
    | `LAB-JEN-04` | 🟢 CORE | Git Repository ile Otomatik Build ve Webhook Yapılandırması | JENKINS | 40 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-04-git-scm-webhook/) |
    | `LAB-JEN-05` | 🟢 CORE | İlk Declarative Jenkins Pipeline ve Jenkinsfile Temelleri | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-05-declarative-pipeline/) |
    | `LAB-JEN-06` | 🟡 PRACTITIONER | Environment Değişkenleri, Parametreler ve Güvenli Credentials Yönetimi | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-06-environment-credentials/) |
    | `LAB-JEN-07` | 🟡 PRACTITIONER | Uygulama Derleme, Birim Testleri ve JUnit Test Raporlama | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-07-build-unit-test-reports/) |
    | `LAB-JEN-08` | 🟡 PRACTITIONER | Pipeline İçinde Docker İmaj Derleme, Tagging ve Smoke Test | JENKINS | 45 dk | `8080, 5001` | [Labı Aç →](../day3/LAB-JEN-08-docker-build-smoke-test/) |
    | `LAB-JEN-09` | 🟡 PRACTITIONER | SonarQube ile Statik Kod Analizi ve Quality Gate Entegrasyonu | JENKINS | 50 dk | `8080, 9000` | [Labı Aç →](../day3/LAB-JEN-09-sonarqube-quality-gate/) |
    | `LAB-JEN-10` | 🟡 PRACTITIONER | Trivy ile Dosya Sistemi ve İmaj Güvenlik Taraması (DevSecOps Gate) | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-10-trivy-security-scan/) |
    | `LAB-JEN-11` | 🟡 PRACTITIONER | Harbor Private Registry Entegrasyonu ve İmaj Dağıtımı | JENKINS | 45 dk | `8080, 8082` | [Labı Aç →](../day3/LAB-JEN-11-harbor-registry-push/) |
    | `LAB-JEN-12` | 🔴 ADVANCED | Kubernetes (kind) Kümesine Otomatik Deployment (CD) | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-12-kubernetes-cd-deploy/) |
    | `LAB-JEN-13` | 🔴 ADVANCED | Rolling Update, Canlı Doğrulama ve Otomatik Rollback | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-13-rolling-update-rollback/) |
    | `LAB-JEN-14` | 🔴 ADVANCED | Jenkins Troubleshooting ve Sorun Giderme Senaryoları | JENKINS | 50 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-14-jenkins-troubleshooting/) |
    | `LAB-JEN-15` | 🔴 ADVANCED | Uçtan Uca DevSecOps Pipeline Capstone Projesi | JENKINS | 60 dk | `8080, 9000, 8082, 80` | [Labı Aç →](../day3/LAB-JEN-15-devsecops-capstone/) |
    | `LAB-GLB-01` | 🟡 PRACTITIONER | GitLab CI/CD Fundamentals | GITLAB-CI | 45 dk | `8081` | [Labı Aç →](../day3/LAB-GLB-01-gitlab-ci-pipeline/) |
    | `LAB-TF-01` | 🟢 CORE | Terraform Docker Provider ve State Lifecycle | TERRAFORM | 45 dk | `8090` | [Labı Aç →](../day3/LAB-TF-01-terraform-docker-provider/) |
    | `LAB-TF-04` | 🔴 ADVANCED | Terraform ve Helm ile Merkezi Kubernetes İzleme | TERRAFORM | 60 dk | `-` | [Labı Aç →](../day3/LAB-TF-04-terraform-helm-centralized-monitoring/) |
    | `LAB-TF-08` | 🔴 ADVANCED | Terraform ile Production AWS VPC | TERRAFORM | 75 dk | `4566` | [Labı Aç →](../day3/LAB-TF-08-terraform-aws-vpc-architecture/) |
    | `LAB-K8S-01` | 🟢 CORE | Kind ile Kubernetes Cluster Kurulumu ve kubectl | KUBERNETES | 30 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-01-kind-cluster-kubectl/) |
    | `LAB-K8S-02` | 🟢 CORE | İlk Pod, YAML ve Pod Yaşam Döngüsü | KUBERNETES | 40 dk | `-` | [Labı Aç →](../day4/LAB-K8S-02-pod-yaml-lifecycle/) |
    | `LAB-K8S-03` | 🟢 CORE | Deployment, ReplicaSet ve Self-Healing | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-03-deployment-self-healing/) |
    | `LAB-K8S-04` | 🟡 PRACTITIONER | Scaling, Rolling Update ve Rollback | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-04-scaling-rollout-rollback/) |
    | `LAB-K8S-05` | 🟡 PRACTITIONER | Service, Port Mapping ve Kubernetes DNS | KUBERNETES | 45 dk | `8080` | [Labı Aç →](../day4/LAB-K8S-05-service-dns/) |
    | `LAB-K8S-06` | 🟡 PRACTITIONER | ConfigMap ve Secret ile Yapılandırma | KUBERNETES | 40 dk | `-` | [Labı Aç →](../day4/LAB-K8S-06-configmap-secret/) |
    | `LAB-K8S-07` | 🟡 PRACTITIONER | Liveness, Readiness ve Resource Limits | KUBERNETES | 50 dk | `-` | [Labı Aç →](../day4/LAB-K8S-07-probes-resources/) |
    | `LAB-K8S-08` | 🟡 PRACTITIONER | PersistentVolume ve PersistentVolumeClaim | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-08-pv-pvc/) |
    | `LAB-K8S-09` | 🟡 PRACTITIONER | Ingress NGINX ile Dışa Açma ve Path Routing | KUBERNETES | 45 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-09-ingress-nginx/) |
    | `LAB-K8S-10` | 🟡 PRACTITIONER | Helm Temelleri, Chart Kurulumu ve Rollback | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-10-helm/) |
    | `LAB-K8S-11` | 🔴 ADVANCED | Kubernetes Troubleshooting ve CrashLoopBackOff | KUBERNETES | 50 dk | `-` | [Labı Aç →](../day4/LAB-K8S-11-troubleshooting/) |
    | `LAB-K8S-12` | 🔴 ADVANCED | Çok Katmanlı Production Kubernetes Mimarisi (Capstone) | KUBERNETES | 60 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-12-capstone/) |
    | `LAB-HLM-01` | 🟡 PRACTITIONER | Helm Chart Deployment | HELM | 45 dk | `-` | [Labı Aç →](../day4/LAB-HLM-01-helm-chart-deployment/) |
    | `LAB-ARG-01` | 🟡 PRACTITIONER | Argo CD GitOps Sync ve Self-Healing | GITOPS | 45 dk | `8085` | [Labı Aç →](../day4/LAB-ARG-01-argocd-gitops-sync/) |
    | `LAB-MON-01` | 🟡 PRACTITIONER | Prometheus ve Grafana Metrics | MONITORING | 45 dk | `3000, 8000, 9090, 9100` | [Labı Aç →](../day5/LAB-MON-01-prometheus-grafana-metrics/) |
    | `LAB-MON-02` | 🟡 PRACTITIONER | Prometheus Alertmanager Kuralları | MONITORING | 45 dk | `9090, 9093` | [Labı Aç →](../day5/LAB-MON-02-alertmanager-rules/) |
    | `LAB-LOG-01` | 🟡 PRACTITIONER | ELK ile Nginx Loglarını Merkezileştirme | LOGGING | 75 dk | `-` | [Labı Aç →](../day5/LAB-LOG-01-centralized-logging/) |
    | `LAB-LOG-02` | 🔴 ADVANCED | İleri ELK Gözlemlenebilirliği | LOGGING | 90 dk | `-` | [Labı Aç →](../day5/LAB-LOG-02-elk-centralized-logging/) |
    | `LAB-INC-01` | 🔴 ADVANCED | Kubernetes War Room ve Postmortem | INCIDENT-RESPONSE | 45 dk | `-` | [Labı Aç →](../day5/LAB-INC-01-k8s-crashloop-postmortem/) |
    | `LAB-CAP-01` | 🔴 ADVANCED | Code to Observability DevOps Capstone | CAPSTONE | 90 dk | `3000, 8000, 8082, 8085, 9090` | [Labı Aç →](../day5/LAB-CAP-01-end-to-end-devops/) |
    | `LAB-LNX-02` | 🟡 PRACTITIONER | Nginx Üzerinde Let's Encrypt SSL/TLS ve Certbot Otomasyonu | LINUX | 40 dk | `80, 443` | [Labı Aç →](../day1/LAB-LNX-02-nginx-letsencrypt-ssl/) |
    | `LAB-LNX-03` | 🟡 PRACTITIONER | SSH Tunneling (Port Forwarding) ile Güvenli Veritabanı Erişimi | LINUX | 35 dk | `-` | [Labı Aç →](../day1/LAB-LNX-03-ssh-tunnel-mysql/) |
    | `LAB-GHA-01` | 🟡 PRACTITIONER | GitHub Actions ile Sürekli Entegrasyon (CI) ve Otomatik Test | CI-CD | 45 dk | `-` | [Labı Aç →](../day3/LAB-GHA-01-github-actions-ci/) |

=== "🟢 CORE — Temel Seviye (17 Lab)"

    DevOps kültürüne giriş, Linux yönetimi, Git sürüm kontrolü, Docker ve Kubernetes temelleri gibi çekirdek yetkinlikleri kazandırır.

    | Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-ENV-00` | Ubuntu Server 24.04 DevOps Ortamı Kurulumu ve Doğrulama | ENVIRONMENT | 90 dk | `-` | [Labı Aç →](../env/LAB-ENV-00-environment-setup/) |
    | `LAB-LNX-01` | Linux Preflight ve Systemd Servis İncelemesi | LINUX | 30 dk | `22` | [Labı Aç →](../day1/LAB-LNX-01-linux-preflight/) |
    | `LAB-GIT-01` | Git Workflow, Branching ve Conflict Resolution | GIT | 45 dk | `-` | [Labı Aç →](../day1/LAB-GIT-01-git-workflow/) |
    | `LAB-DOC-01` | İlk Docker Konteyneri ve Temel Komutlar | DOCKER | 35 dk | `8080` | [Labı Aç →](../day1/LAB-DOC-01-docker-first-container/) |
    | `LAB-DOC-02` | Konteyner Yaşam Döngüsü ve Teşhis Komutları | DOCKER | 40 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-02-docker-lifecycle-diagnostics/) |
    | `LAB-DOC-03` | Docker İmaj, Etiketleme ve Registry Yönetimi | DOCKER | 45 dk | `5000` | [Labı Aç →](../day2/LAB-DOC-03-docker-image-registry/) |
    | `LAB-DOC-04` | Docker Volumes ve Veri Kalıcılığı | DOCKER | 45 dk | `5432` | [Labı Aç →](../day2/LAB-DOC-04-docker-volumes-persistence/) |
    | `LAB-DOC-05` | Ortam Değişkenleri, .env ve Konfigürasyon Yönetimi | DOCKER | 35 dk | `3000` | [Labı Aç →](../day2/LAB-DOC-05-docker-env-secrets/) |
    | `LAB-JEN-01` | Docker Compose ile Jenkins Kurulumu ve Nginx Reverse Proxy | JENKINS | 40 dk | `8080, 8443` | [Labı Aç →](../day3/LAB-JEN-01-docker-compose-setup/) |
    | `LAB-JEN-02` | Jenkins İlk Yapılandırma, Yönetici Hesabı ve Eklenti Yönetimi | JENKINS | 35 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-02-initial-setup-plugins/) |
    | `LAB-JEN-03` | İlk Freestyle Build Job ve Workspace Temelleri | JENKINS | 35 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-03-first-freestyle-job/) |
    | `LAB-JEN-04` | Git Repository ile Otomatik Build ve Webhook Yapılandırması | JENKINS | 40 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-04-git-scm-webhook/) |
    | `LAB-JEN-05` | İlk Declarative Jenkins Pipeline ve Jenkinsfile Temelleri | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-05-declarative-pipeline/) |
    | `LAB-TF-01` | Terraform Docker Provider ve State Lifecycle | TERRAFORM | 45 dk | `8090` | [Labı Aç →](../day3/LAB-TF-01-terraform-docker-provider/) |
    | `LAB-K8S-01` | Kind ile Kubernetes Cluster Kurulumu ve kubectl | KUBERNETES | 30 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-01-kind-cluster-kubectl/) |
    | `LAB-K8S-02` | İlk Pod, YAML ve Pod Yaşam Döngüsü | KUBERNETES | 40 dk | `-` | [Labı Aç →](../day4/LAB-K8S-02-pod-yaml-lifecycle/) |
    | `LAB-K8S-03` | Deployment, ReplicaSet ve Self-Healing | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-03-deployment-self-healing/) |

=== "🟡 PRACTITIONER — Üretim Standartları (32 Lab)"

    Kurumsal ortamlarda kullanılan ileri düzey Docker multi-stage, container networking, Java Spring Boot, Docker Compose, Jenkins, GitLab CI, Terraform, Kubernetes, Helm ve Argo CD GitOps uygulamalarını kapsar.

    | Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-DOC-06` | Docker Network, Port İzolasyonu ve DNS Çözümleme | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-06-docker-networks-dns/) |
    | `LAB-DOC-07` | İlk Dockerfile ile İmaj Oluşturma | DOCKER | 40 dk | `5000` | [Labı Aç →](../day2/LAB-DOC-07-dockerfile-basics/) |
    | `LAB-DOC-08` | Dockerfile Katmanları ve BuildKit Cache | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-08-dockerfile-optimization/) |
    | `LAB-DOC-09` | Multi-Stage Build ve Boyut Optimizasyonu | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-09-docker-multistage-build/) |
    | `LAB-DOC-11` | Java Spring Boot Konteynerleştirme ve JVM Optimizasyonu | DOCKER | 50 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-11-docker-java-spring-boot/) |
    | `LAB-DOC-12` | React SPA ve Nginx Frontend Container | DOCKER | 40 dk | `80` | [Labı Aç →](../day2/LAB-DOC-12-docker-react-nginx/) |
    | `LAB-DOC-13` | Docker Compose ile Çok Katmanlı Mimari | DOCKER | 50 dk | `80, 3000, 5432` | [Labı Aç →](../day2/LAB-DOC-13-docker-compose-multitier/) |
    | `LAB-DOC-15` | Docker Loglama ve Gözlemlenebilirlik | DOCKER | 40 dk | `8080, 8081` | [Labı Aç →](../day2/LAB-DOC-15-docker-logging-observability/) |
    | `LAB-DOC-16` | Trivy Güvenlik Taraması, SBOM ve Harbor Entegrasyonu | DOCKER | 50 dk | `80, 443` | [Labı Aç →](../day2/LAB-DOC-16-trivy-harbor-integration/) |
    | `LAB-DOC-17` | İmaj ve Volume Yedekleme / Geri Yükleme | DOCKER | 45 dk | `5432` | [Labı Aç →](../day2/LAB-DOC-17-docker-backup-restore/) |
    | `LAB-JEN-06` | Environment Değişkenleri, Parametreler ve Güvenli Credentials Yönetimi | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-06-environment-credentials/) |
    | `LAB-JEN-07` | Uygulama Derleme, Birim Testleri ve JUnit Test Raporlama | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-07-build-unit-test-reports/) |
    | `LAB-JEN-08` | Pipeline İçinde Docker İmaj Derleme, Tagging ve Smoke Test | JENKINS | 45 dk | `8080, 5001` | [Labı Aç →](../day3/LAB-JEN-08-docker-build-smoke-test/) |
    | `LAB-JEN-09` | SonarQube ile Statik Kod Analizi ve Quality Gate Entegrasyonu | JENKINS | 50 dk | `8080, 9000` | [Labı Aç →](../day3/LAB-JEN-09-sonarqube-quality-gate/) |
    | `LAB-JEN-10` | Trivy ile Dosya Sistemi ve İmaj Güvenlik Taraması (DevSecOps Gate) | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-10-trivy-security-scan/) |
    | `LAB-JEN-11` | Harbor Private Registry Entegrasyonu ve İmaj Dağıtımı | JENKINS | 45 dk | `8080, 8082` | [Labı Aç →](../day3/LAB-JEN-11-harbor-registry-push/) |
    | `LAB-GLB-01` | GitLab CI/CD Fundamentals | GITLAB-CI | 45 dk | `8081` | [Labı Aç →](../day3/LAB-GLB-01-gitlab-ci-pipeline/) |
    | `LAB-K8S-04` | Scaling, Rolling Update ve Rollback | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-04-scaling-rollout-rollback/) |
    | `LAB-K8S-05` | Service, Port Mapping ve Kubernetes DNS | KUBERNETES | 45 dk | `8080` | [Labı Aç →](../day4/LAB-K8S-05-service-dns/) |
    | `LAB-K8S-06` | ConfigMap ve Secret ile Yapılandırma | KUBERNETES | 40 dk | `-` | [Labı Aç →](../day4/LAB-K8S-06-configmap-secret/) |
    | `LAB-K8S-07` | Liveness, Readiness ve Resource Limits | KUBERNETES | 50 dk | `-` | [Labı Aç →](../day4/LAB-K8S-07-probes-resources/) |
    | `LAB-K8S-08` | PersistentVolume ve PersistentVolumeClaim | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-08-pv-pvc/) |
    | `LAB-K8S-09` | Ingress NGINX ile Dışa Açma ve Path Routing | KUBERNETES | 45 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-09-ingress-nginx/) |
    | `LAB-K8S-10` | Helm Temelleri, Chart Kurulumu ve Rollback | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-10-helm/) |
    | `LAB-HLM-01` | Helm Chart Deployment | HELM | 45 dk | `-` | [Labı Aç →](../day4/LAB-HLM-01-helm-chart-deployment/) |
    | `LAB-ARG-01` | Argo CD GitOps Sync ve Self-Healing | GITOPS | 45 dk | `8085` | [Labı Aç →](../day4/LAB-ARG-01-argocd-gitops-sync/) |
    | `LAB-MON-01` | Prometheus ve Grafana Metrics | MONITORING | 45 dk | `3000, 8000, 9090, 9100` | [Labı Aç →](../day5/LAB-MON-01-prometheus-grafana-metrics/) |
    | `LAB-MON-02` | Prometheus Alertmanager Kuralları | MONITORING | 45 dk | `9090, 9093` | [Labı Aç →](../day5/LAB-MON-02-alertmanager-rules/) |
    | `LAB-LOG-01` | ELK ile Nginx Loglarını Merkezileştirme | LOGGING | 75 dk | `-` | [Labı Aç →](../day5/LAB-LOG-01-centralized-logging/) |
    | `LAB-LNX-02` | Nginx Üzerinde Let's Encrypt SSL/TLS ve Certbot Otomasyonu | LINUX | 40 dk | `80, 443` | [Labı Aç →](../day1/LAB-LNX-02-nginx-letsencrypt-ssl/) |
    | `LAB-LNX-03` | SSH Tunneling (Port Forwarding) ile Güvenli Veritabanı Erişimi | LINUX | 35 dk | `-` | [Labı Aç →](../day1/LAB-LNX-03-ssh-tunnel-mysql/) |
    | `LAB-GHA-01` | GitHub Actions ile Sürekli Entegrasyon (CI) ve Otomatik Test | CI-CD | 45 dk | `-` | [Labı Aç →](../day3/LAB-GHA-01-github-actions-ci/) |

=== "🔴 ADVANCED — İleri Seviye ve Capstone (16 Lab)"

    Üretim seviyesinde gözlemlenebilirlik, Kubernetes troubleshooting, yüksek erişilebilirlik ve uçtan uca DevSecOps capstone projelerini içerir.

    | Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-DOC-10` | Docker Runtime Güvenliği ve Hardening | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-10-docker-runtime-security/) |
    | `LAB-DOC-14` | Healthcheck, Restart Policy ve Kaynak Limitleri | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-14-docker-healthcheck-limits/) |
    | `LAB-DOC-18` | Docker Sorun Giderme ve Teşhis Senaryoları | DOCKER | 55 dk | `8080, 5432` | [Labı Aç →](../day2/LAB-DOC-18-docker-troubleshooting/) |
    | `LAB-DOC-19` | Production Docker Compose Desenleri | DOCKER | 50 dk | `80, 3000` | [Labı Aç →](../day2/LAB-DOC-19-docker-compose-production-patterns/) |
    | `LAB-DOC-20` | Docker Final Capstone Projesi: Üretim Seviyesi Mikroservis Platformu | DOCKER | 90 dk | `80, 3000, 5432, 6379` | [Labı Aç →](../day2/LAB-DOC-20-docker-capstone/) |
    | `LAB-JEN-12` | Kubernetes (kind) Kümesine Otomatik Deployment (CD) | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-12-kubernetes-cd-deploy/) |
    | `LAB-JEN-13` | Rolling Update, Canlı Doğrulama ve Otomatik Rollback | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-13-rolling-update-rollback/) |
    | `LAB-JEN-14` | Jenkins Troubleshooting ve Sorun Giderme Senaryoları | JENKINS | 50 dk | `8080` | [Labı Aç →](../day3/LAB-JEN-14-jenkins-troubleshooting/) |
    | `LAB-JEN-15` | Uçtan Uca DevSecOps Pipeline Capstone Projesi | JENKINS | 60 dk | `8080, 9000, 8082, 80` | [Labı Aç →](../day3/LAB-JEN-15-devsecops-capstone/) |
    | `LAB-TF-04` | Terraform ve Helm ile Merkezi Kubernetes İzleme | TERRAFORM | 60 dk | `-` | [Labı Aç →](../day3/LAB-TF-04-terraform-helm-centralized-monitoring/) |
    | `LAB-TF-08` | Terraform ile Production AWS VPC | TERRAFORM | 75 dk | `4566` | [Labı Aç →](../day3/LAB-TF-08-terraform-aws-vpc-architecture/) |
    | `LAB-K8S-11` | Kubernetes Troubleshooting ve CrashLoopBackOff | KUBERNETES | 50 dk | `-` | [Labı Aç →](../day4/LAB-K8S-11-troubleshooting/) |
    | `LAB-K8S-12` | Çok Katmanlı Production Kubernetes Mimarisi (Capstone) | KUBERNETES | 60 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-12-capstone/) |
    | `LAB-LOG-02` | İleri ELK Gözlemlenebilirliği | LOGGING | 90 dk | `-` | [Labı Aç →](../day5/LAB-LOG-02-elk-centralized-logging/) |
    | `LAB-INC-01` | Kubernetes War Room ve Postmortem | INCIDENT-RESPONSE | 45 dk | `-` | [Labı Aç →](../day5/LAB-INC-01-k8s-crashloop-postmortem/) |
    | `LAB-CAP-01` | Code to Observability DevOps Capstone | CAPSTONE | 90 dk | `3000, 8000, 8082, 8085, 9090` | [Labı Aç →](../day5/LAB-CAP-01-end-to-end-devops/) |
