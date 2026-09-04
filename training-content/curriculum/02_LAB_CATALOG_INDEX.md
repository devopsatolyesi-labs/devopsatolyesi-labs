# 02 — DevOps Lab Kataloğu ve Zorluk Seviyeleri

DevOps Atölyesi laboratuvar kütüphanesi, katılımcıların bilgi seviyelerine ve hedeflerine göre **3 ana zorluk düzeyinde** yapılandırılmıştır.

Aşağıdaki sekmeleri kullanarak dilediğiniz seviyedeki labları listeleyebilir ve doğrudan çalışmaya başlayabilirsiniz:

=== "Tüm Lablar (34 Lab)"

    | Lab ID | Seviye | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-ENV-00` | 🟢 CORE | Ubuntu Server 24.04 DevOps Ortamı Kurulumu ve Doğrulama | ENVIRONMENT | 90 dk | `-` | [Labı Aç →](../env/LAB-ENV-00-environment-setup/) |
    | `LAB-LNX-01` | 🟢 CORE | Linux Preflight ve Systemd Servis İncelemesi | LINUX | 30 dk | `22` | [Labı Aç →](../day1/LAB-LNX-01-linux-preflight/) |
    | `LAB-GIT-01` | 🟢 CORE | Git Workflow, Branching ve Conflict Resolution | GIT | 45 dk | `-` | [Labı Aç →](../day1/LAB-GIT-01-git-workflow/) |
    | `LAB-DOC-01` | 🟢 CORE | İlk Docker Konteyneri ve Port Mapping | DOCKER | 30 dk | `8080` | [Labı Aç →](../day1/LAB-DOC-01-docker-first-container/) |
    | `LAB-DOC-02` | 🟢 CORE | Container Lifecycle, Env ve Volume Persistence | DOCKER | 40 dk | `5432` | [Labı Aç →](../day1/LAB-DOC-02-docker-volumes-env/) |
    | `LAB-DOC-03` | 🟡 PRACTITIONER | Docker İmaj Optimizasyonu ve Registry Dağıtımı | DOCKER | 60 dk | `8000, 8082` | [Labı Aç →](../day2/LAB-DOC-03-dockerfile-optimization/) |
    | `LAB-DOC-09` | 🟡 PRACTITIONER | User-Defined Docker Network ve Container DNS | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-09-docker-networks-dns/) |
    | `LAB-DOC-04` | 🟡 PRACTITIONER | Multi-Stage Build, Non-Root ve Image Hardening | DOCKER | 45 dk | `-` | [Labı Aç →](../day2/LAB-DOC-04-docker-multistage-hardening/) |
    | `LAB-DOC-05` | 🟡 PRACTITIONER | Docker Compose Multi-Tier Orchestration | DOCKER | 60 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-05-docker-compose-multitier/) |
    | `LAB-DOC-06` | 🟡 PRACTITIONER | Trivy Container Security Gate | CONTAINER-SECURITY | 30 dk | `-` | [Labı Aç →](../day2/LAB-DOC-06-trivy-harbor-integration/) |
    | `LAB-DOC-13` | 🔴 ADVANCED | Production-Ready Docker Compose Patterns | DOCKER | 60 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-13-docker-compose-production-patterns/) |
    | `LAB-JNK-01` | 🟢 CORE | Jenkins Declarative Pipeline | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JNK-01-jenkins-declarative-pipeline/) |
    | `LAB-JNK-02` | 🟡 PRACTITIONER | Jenkins Secure Pipeline, SonarQube, Trivy ve Harbor | JENKINS | 60 dk | `8080, 8082, 9000` | [Labı Aç →](../day3/LAB-JNK-02-jenkins-secure-pipeline/) |
    | `LAB-GLB-01` | 🟡 PRACTITIONER | GitLab CI/CD Fundamentals | GITLAB-CI | 45 dk | `8081` | [Labı Aç →](../day3/LAB-GLB-01-gitlab-ci-pipeline/) |
    | `LAB-TF-01` | 🟢 CORE | Terraform Docker Provider ve State Lifecycle | TERRAFORM | 45 dk | `8090` | [Labı Aç →](../day3/LAB-TF-01-terraform-docker-provider/) |
    | `LAB-TF-04` | 🔴 ADVANCED | Terraform ve Helm ile Merkezi Kubernetes İzleme | TERRAFORM | 60 dk | `-` | [Labı Aç →](../day3/LAB-TF-04-terraform-helm-centralized-monitoring/) |
    | `LAB-TF-08` | 🔴 ADVANCED | Terraform ile Production AWS VPC | TERRAFORM | 75 dk | `4566` | [Labı Aç →](../day3/LAB-TF-08-terraform-aws-vpc-architecture/) |
    | `LAB-K8S-01` | 🟢 CORE | kind Multi-Node Cluster ve kubectl Preflight | KUBERNETES | 45 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-01-kind-pods-deployments/) |
    | `LAB-K8S-02` | 🟢 CORE | Services, ConfigMaps ve Secrets | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-02-services-config-secrets/) |
    | `LAB-K8S-03` | 🟡 PRACTITIONER | Production Workloads, Probes, Rollouts ve PVC | KUBERNETES | 60 dk | `-` | [Labı Aç →](../day4/LAB-K8S-03-production-workloads/) |
    | `LAB-HLM-01` | 🟡 PRACTITIONER | Helm Chart Deployment | HELM | 45 dk | `-` | [Labı Aç →](../day4/LAB-HLM-01-helm-chart-deployment/) |
    | `LAB-ARG-01` | 🟡 PRACTITIONER | Argo CD GitOps Sync ve Self-Healing | GITOPS | 45 dk | `8085` | [Labı Aç →](../day4/LAB-ARG-01-argocd-gitops-sync/) |
    | `LAB-MON-01` | 🟡 PRACTITIONER | Prometheus ve Grafana Metrics | MONITORING | 45 dk | `3000, 8000, 9090, 9100` | [Labı Aç →](../day5/LAB-MON-01-prometheus-grafana-metrics/) |
    | `LAB-MON-02` | 🟡 PRACTITIONER | Prometheus Alertmanager Kuralları | MONITORING | 45 dk | `9090, 9093` | [Labı Aç →](../day5/LAB-MON-02-alertmanager-rules/) |
    | `LAB-LOG-01` | 🟡 PRACTITIONER | ELK ile Nginx Loglarını Merkezileştirme | LOGGING | 75 dk | `-` | [Labı Aç →](../day5/LAB-LOG-01-centralized-logging/) |
    | `LAB-LOG-02` | 🔴 ADVANCED | İleri ELK Gözlemlenebilirliği | LOGGING | 90 dk | `-` | [Labı Aç →](../day5/LAB-LOG-02-elk-centralized-logging/) |
    | `LAB-INC-01` | 🔴 ADVANCED | Kubernetes War Room ve Postmortem | INCIDENT-RESPONSE | 45 dk | `-` | [Labı Aç →](../day5/LAB-INC-01-k8s-crashloop-postmortem/) |
    | `LAB-CAP-01` | 🔴 ADVANCED | Code to Observability DevOps Capstone | CAPSTONE | 90 dk | `3000, 8000, 8082, 8085, 9090` | [Labı Aç →](../day5/LAB-CAP-01-end-to-end-devops/) |
    | `LAB-DOC-10` | 🟡 PRACTITIONER | Docker İmaj, Konteyner ve Volume Yedekleme / Geri Yükleme | DOCKER | 40 dk | `-` | [Labı Aç →](../day2/LAB-DOC-10-docker-backup-restore/) |
    | `LAB-LNX-02` | 🟡 PRACTITIONER | Nginx Üzerinde Let's Encrypt SSL/TLS ve Certbot Otomasyonu | LINUX | 40 dk | `80, 443` | [Labı Aç →](../day1/LAB-LNX-02-nginx-letsencrypt-ssl/) |
    | `LAB-LNX-03` | 🟡 PRACTITIONER | SSH Tunneling (Port Forwarding) ile Güvenli Veritabanı Erişimi | LINUX | 35 dk | `-` | [Labı Aç →](../day1/LAB-LNX-03-ssh-tunnel-mysql/) |
    | `LAB-DOC-07` | 🟡 PRACTITIONER | Java Spring Boot Multi-Stage Build ve JVM Optimizasyonu | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-07-docker-java-spring-boot/) |
    | `LAB-DOC-08` | 🟡 PRACTITIONER | Modern React / Statik Frontend Build ve Nginx Container | DOCKER | 40 dk | `80` | [Labı Aç →](../day2/LAB-DOC-08-docker-react-nginx/) |
    | `LAB-GHA-01` | 🟡 PRACTITIONER | GitHub Actions ile Sürekli Entegrasyon (CI) ve Otomatik Test | CI-CD | 45 dk | `-` | [Labı Aç →](../day3/LAB-GHA-01-github-actions-ci/) |

=== "🟢 CORE — Temel Seviye (9 Lab)"

    DevOps kültürüne giriş, Linux yönetimi, Git sürüm kontrolü ve ilk Docker konteyneri gibi temel yetkinlikleri kazandırır.

    | Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-ENV-00` | Ubuntu Server 24.04 DevOps Ortamı Kurulumu ve Doğrulama | ENVIRONMENT | 90 dk | `-` | [Labı Aç →](../env/LAB-ENV-00-environment-setup/) |
    | `LAB-LNX-01` | Linux Preflight ve Systemd Servis İncelemesi | LINUX | 30 dk | `22` | [Labı Aç →](../day1/LAB-LNX-01-linux-preflight/) |
    | `LAB-GIT-01` | Git Workflow, Branching ve Conflict Resolution | GIT | 45 dk | `-` | [Labı Aç →](../day1/LAB-GIT-01-git-workflow/) |
    | `LAB-DOC-01` | İlk Docker Konteyneri ve Port Mapping | DOCKER | 30 dk | `8080` | [Labı Aç →](../day1/LAB-DOC-01-docker-first-container/) |
    | `LAB-DOC-02` | Container Lifecycle, Env ve Volume Persistence | DOCKER | 40 dk | `5432` | [Labı Aç →](../day1/LAB-DOC-02-docker-volumes-env/) |
    | `LAB-JNK-01` | Jenkins Declarative Pipeline | JENKINS | 45 dk | `8080` | [Labı Aç →](../day3/LAB-JNK-01-jenkins-declarative-pipeline/) |
    | `LAB-TF-01` | Terraform Docker Provider ve State Lifecycle | TERRAFORM | 45 dk | `8090` | [Labı Aç →](../day3/LAB-TF-01-terraform-docker-provider/) |
    | `LAB-K8S-01` | kind Multi-Node Cluster ve kubectl Preflight | KUBERNETES | 45 dk | `80, 443` | [Labı Aç →](../day4/LAB-K8S-01-kind-pods-deployments/) |
    | `LAB-K8S-02` | Services, ConfigMaps ve Secrets | KUBERNETES | 45 dk | `-` | [Labı Aç →](../day4/LAB-K8S-02-services-config-secrets/) |

=== "🟡 PRACTITIONER — Üretim Standartları (19 Lab)"

    Kurumsal ortamlarda kullanılan ileri düzey Docker multi-stage hardening, Java Spring Boot JVM optimizasyonu, Docker Compose, Jenkins, Terraform, Kubernetes, Helm ve Argo CD GitOps uygulamalarını kapsar.

    | Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-DOC-03` | Docker İmaj Optimizasyonu ve Registry Dağıtımı | DOCKER | 60 dk | `8000, 8082` | [Labı Aç →](../day2/LAB-DOC-03-dockerfile-optimization/) |
    | `LAB-DOC-09` | User-Defined Docker Network ve Container DNS | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-09-docker-networks-dns/) |
    | `LAB-DOC-04` | Multi-Stage Build, Non-Root ve Image Hardening | DOCKER | 45 dk | `-` | [Labı Aç →](../day2/LAB-DOC-04-docker-multistage-hardening/) |
    | `LAB-DOC-05` | Docker Compose Multi-Tier Orchestration | DOCKER | 60 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-05-docker-compose-multitier/) |
    | `LAB-DOC-06` | Trivy Container Security Gate | CONTAINER-SECURITY | 30 dk | `-` | [Labı Aç →](../day2/LAB-DOC-06-trivy-harbor-integration/) |
    | `LAB-JNK-02` | Jenkins Secure Pipeline, SonarQube, Trivy ve Harbor | JENKINS | 60 dk | `8080, 8082, 9000` | [Labı Aç →](../day3/LAB-JNK-02-jenkins-secure-pipeline/) |
    | `LAB-GLB-01` | GitLab CI/CD Fundamentals | GITLAB-CI | 45 dk | `8081` | [Labı Aç →](../day3/LAB-GLB-01-gitlab-ci-pipeline/) |
    | `LAB-K8S-03` | Production Workloads, Probes, Rollouts ve PVC | KUBERNETES | 60 dk | `-` | [Labı Aç →](../day4/LAB-K8S-03-production-workloads/) |
    | `LAB-HLM-01` | Helm Chart Deployment | HELM | 45 dk | `-` | [Labı Aç →](../day4/LAB-HLM-01-helm-chart-deployment/) |
    | `LAB-ARG-01` | Argo CD GitOps Sync ve Self-Healing | GITOPS | 45 dk | `8085` | [Labı Aç →](../day4/LAB-ARG-01-argocd-gitops-sync/) |
    | `LAB-MON-01` | Prometheus ve Grafana Metrics | MONITORING | 45 dk | `3000, 8000, 9090, 9100` | [Labı Aç →](../day5/LAB-MON-01-prometheus-grafana-metrics/) |
    | `LAB-MON-02` | Prometheus Alertmanager Kuralları | MONITORING | 45 dk | `9090, 9093` | [Labı Aç →](../day5/LAB-MON-02-alertmanager-rules/) |
    | `LAB-LOG-01` | ELK ile Nginx Loglarını Merkezileştirme | LOGGING | 75 dk | `-` | [Labı Aç →](../day5/LAB-LOG-01-centralized-logging/) |
    | `LAB-DOC-10` | Docker İmaj, Konteyner ve Volume Yedekleme / Geri Yükleme | DOCKER | 40 dk | `-` | [Labı Aç →](../day2/LAB-DOC-10-docker-backup-restore/) |
    | `LAB-LNX-02` | Nginx Üzerinde Let's Encrypt SSL/TLS ve Certbot Otomasyonu | LINUX | 40 dk | `80, 443` | [Labı Aç →](../day1/LAB-LNX-02-nginx-letsencrypt-ssl/) |
    | `LAB-LNX-03` | SSH Tunneling (Port Forwarding) ile Güvenli Veritabanı Erişimi | LINUX | 35 dk | `-` | [Labı Aç →](../day1/LAB-LNX-03-ssh-tunnel-mysql/) |
    | `LAB-DOC-07` | Java Spring Boot Multi-Stage Build ve JVM Optimizasyonu | DOCKER | 45 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-07-docker-java-spring-boot/) |
    | `LAB-DOC-08` | Modern React / Statik Frontend Build ve Nginx Container | DOCKER | 40 dk | `80` | [Labı Aç →](../day2/LAB-DOC-08-docker-react-nginx/) |
    | `LAB-GHA-01` | GitHub Actions ile Sürekli Entegrasyon (CI) ve Otomatik Test | CI-CD | 45 dk | `-` | [Labı Aç →](../day3/LAB-GHA-01-github-actions-ci/) |

=== "🔴 ADVANCED — İleri Seviye & Capstone (6 Lab)"

    Gerçek dünya felaket senaryoları (Incident Response / War Room), merkezi ELK log analitiği, Alertmanager kuralları ve uçtan uca DevOps Capstone projesini içerir.

    | Lab ID | Lab Başlığı | Konu | Süre | Portlar | İncele |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | `LAB-DOC-13` | Production-Ready Docker Compose Patterns | DOCKER | 60 dk | `8080` | [Labı Aç →](../day2/LAB-DOC-13-docker-compose-production-patterns/) |
    | `LAB-TF-04` | Terraform ve Helm ile Merkezi Kubernetes İzleme | TERRAFORM | 60 dk | `-` | [Labı Aç →](../day3/LAB-TF-04-terraform-helm-centralized-monitoring/) |
    | `LAB-TF-08` | Terraform ile Production AWS VPC | TERRAFORM | 75 dk | `4566` | [Labı Aç →](../day3/LAB-TF-08-terraform-aws-vpc-architecture/) |
    | `LAB-LOG-02` | İleri ELK Gözlemlenebilirliği | LOGGING | 90 dk | `-` | [Labı Aç →](../day5/LAB-LOG-02-elk-centralized-logging/) |
    | `LAB-INC-01` | Kubernetes War Room ve Postmortem | INCIDENT-RESPONSE | 45 dk | `-` | [Labı Aç →](../day5/LAB-INC-01-k8s-crashloop-postmortem/) |
    | `LAB-CAP-01` | Code to Observability DevOps Capstone | CAPSTONE | 90 dk | `3000, 8000, 8082, 8085, 9090` | [Labı Aç →](../day5/LAB-CAP-01-end-to-end-devops/) |
