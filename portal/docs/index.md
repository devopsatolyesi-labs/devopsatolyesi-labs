# DevOps Atölyesi — Eğitim ve Laboratuvar Portalı

Hoş geldiniz! Bu portal, **DevOps Practitioner** ve **Docker & Kubernetes** eğitim programlarının uygulamalı laboratuvarlarını, üretim standartlarında kurulum rehberlerini, cheat sheet'leri ve uçtan uca capstone projelerini barındırır.

Tüm lablar kurumsal standartlarda hazırlanmış olup; adım adım uygulama rehberleri, hızlı komut referansları, interaktif senaryo soruları ve otomatik doğrulama (`scripts/validate.sh`) araçları içerir.

---

## 🚀 Hızlı Başlangıç: Ortam ve Kurulum Hub

Lablara başlamadan önce ihtiyaç duyacağınız araçları ve altyapıyı **[Kurulum & Araç Hazırlığı](setup/index.md)** bölümünden tek tıkla kurabilirsiniz:

<div class="grid cards" markdown>

-   :material-docker:{ .lg .middle } **Docker Engine & Compose**

    ---

    Ubuntu/Debian üzerine resmi Docker Engine, Buildx ve Docker Compose v2 kurulumu.

    [:octicons-arrow-right-24: Kuruluma Git](setup/docker-engine.md)

-   :material-kubernetes:{ .lg .middle } **Yerel Kubernetes (kind)**

    ---

    Local Docker üzerinde multi-node (1 control-plane, 2 worker) kind kümesi kurulumu ve Ingress/Port mapping.

    [:octicons-arrow-right-24: Kuruluma Git](setup/kind-cluster.md)

-   :material-server-network:{ .lg .middle } **Kubeadm ile Multi-Node K8s**

    ---

    Kurumsal üretim tipi Kubeadm, Containerd ve Calico CNI ile Kubernetes cluster bootstrap rehberi.

    [:octicons-arrow-right-24: Kuruluma Git](setup/kubeadm-cluster.md)

-   :material-file-cog:{ .lg .middle } **Çoklu Kubeconfig Yönetimi**

    ---

    Farklı cluster'ların kubeconfig dosyalarını tek merkezde güvenli şekilde birleştirme ve context değiştirme.

    [:octicons-arrow-right-24: Kuruluma Git](setup/kubeconfig-management.md)

-   :material-harddisk:{ .lg .middle } **NFS Dynamic StorageClass**

    ---

    Kubernetes üzerinde Stateful iş yükleri ve kalıcı veriler (PV/PVC) için dinamik NFS StorageClass kurulumu.

    [:octicons-arrow-right-24: Kuruluma Git](setup/nfs-storageclass.md)

-   :material-hammer-wrench:{ .lg .middle } **Jenkins CI/CD Platformu**

    ---

    Docker ve Kubernetes üzerinde agent tabanlı Jenkins Master/Controller kurulumu ve Pipeline yapılandırması.

    [:octicons-arrow-right-24: Kuruluma Git](setup/jenkins-installation.md)

-   :material-shield-lock:{ .lg .middle } **Harbor Private Registry & TLS**

    ---

    Kurumsal seviyede self-signed TLS sertifikalı Harbor Registry ve Trivy güvenlik taraması kurulumu.

    [:octicons-arrow-right-24: Kuruluma Git](setup/harbor-registry.md)

-   :material-chart-line:{ .lg .middle } **Prometheus & Grafana Monitoring**

    ---

    Kube-Prometheus-Stack, Node Exporter ve hazır Grafana panoları ile tam gözlemlenebilirlik ortamı.

    [:octicons-arrow-right-24: Kuruluma Git](setup/prometheus-grafana.md)

-   :material-database-search:{ .lg .middle } **ELK Stack Merkezi Loglama**

    ---

    Elasticsearch, Logstash/Fluent Bit ve Kibana ile Kubernetes küme içi log toplama ve analiz altyapısı.

    [:octicons-arrow-right-24: Kuruluma Git](setup/elk-stack.md)

-   :material-sync:{ .lg .middle } **Argo CD GitOps Platformu**

    ---

    Kubernetes üzerinde bildirimsel GitOps sürekli teslimat (CD) mimarisi ve Web UI erişim kurulumu.

    [:octicons-arrow-right-24: Kuruluma Git](setup/argocd-setup.md)

</div>

---

## 📚 Eğitim Modülleri ve Laboratuvarlar

<div class="grid cards" markdown>

-   :material-linux:{ .lg .middle } **Temeller (Linux & Git)**

    ---

    Sistem analizi, soketler, systemd servisleri, Let's Encrypt SSL otomasyonu, SSH tunneling ve Git merge çakışma çözümleri.

    - [LAB-LNX-01 — Linux Preflight & DevOps Cheat Sheet](day1/LAB-LNX-01-linux-preflight.md)
    - [LAB-LNX-02 — Nginx Let's Encrypt SSL/TLS Otomasyonu](day1/LAB-LNX-02-nginx-letsencrypt-ssl.md)
    - [LAB-LNX-03 — SSH Tunneling ile MySQL Port Yönlendirme](day1/LAB-LNX-03-ssh-tunnel-mysql.md)
    - [LAB-GIT-01 — Git Workflow & Branch Stratejileri](day1/LAB-GIT-01-git-workflow.md)

-   :material-docker:{ .lg .middle } **Docker & Container Dünyası**

    ---

    Konteyner yaşam döngüsü, Dockerfile katman optimizasyonu, Multi-stage hardening (Non-root UID 10001), Compose, Networks, Java Spring Boot ve Trivy güvenlik taraması.

    - [LAB-DOC-01 — İlk Konteyner & Docker CLI Cheat Sheet](day1/LAB-DOC-01-docker-first-container.md)
    - [LAB-DOC-02 — Kalıcı Volumes ve Ortam Değişkenleri](day1/LAB-DOC-02-docker-volumes-env.md)
    - [LAB-DOC-03 — Dockerfile Optimizasyonu & Cache](day2/LAB-DOC-03-dockerfile-optimization.md)
    - [LAB-DOC-09 — Docker User-Defined Network & DNS](day2/LAB-DOC-09-docker-networks-dns.md)
    - [LAB-DOC-04 — Multi-Stage Build & Hardening](day2/LAB-DOC-04-docker-multistage-hardening.md)
    - [LAB-DOC-07 — Java Spring Boot & JVM Optimizasyonu](day2/LAB-DOC-07-docker-java-spring-boot.md)
    - [LAB-DOC-08 — React SPA & Nginx Production Web](day2/LAB-DOC-08-docker-react-nginx.md)
    - [LAB-DOC-05 — Docker Compose Çok Katmanlı Mimari](day2/LAB-DOC-05-docker-compose-multitier.md)
    - [LAB-DOC-06 — Trivy & Harbor Güvenlik Kapısı](day2/LAB-DOC-06-trivy-harbor-integration.md)
    - [LAB-DOC-10 — Konteyner & İmaj Yedekleme (Backup/Restore)](day2/LAB-DOC-10-docker-backup-restore.md)
    - [LAB-DOC-13 — Production Compose Kalıpları](day2/LAB-DOC-13-docker-compose-production-patterns.md)

-   :material-pipeline:{ .lg .middle } **CI/CD Otomasyon Hatları**

    ---

    Declarative Jenkins Pipeline, GitLab CI/CD, GitHub Actions Matrix testleri ve kurumsal otomasyon kalıpları.

    - [LAB-JNK-01 — Jenkins Declarative Pipeline](day3/LAB-JNK-01-jenkins-declarative-pipeline.md)
    - [LAB-JNK-02 — Jenkins Güvenli Pipeline & Credentials](day3/LAB-JNK-02-jenkins-secure-pipeline.md)
    - [LAB-GLB-01 — GitLab CI/CD ile Otomasyon](day3/LAB-GLB-01-gitlab-ci-pipeline.md)
    - [LAB-GHA-01 — GitHub Actions CI & Docker Buildx](day3/LAB-GHA-01-github-actions-ci.md)

-   :material-terraform:{ .lg .middle } **Infrastructure as Code (Terraform)**

    ---

    Terraform CLI & State yönetimi, Docker provider, Helm provider ile monitoring kurulumu ve AWS VPC mimarisi.

    - [LAB-TF-01 — Terraform Temelleri & State Cheat Sheet](day3/LAB-TF-01-terraform-docker-provider.md)
    - [LAB-TF-04 — Terraform ile Helm & İzleme Altyapısı](day3/LAB-TF-04-terraform-helm-centralized-monitoring.md)
    - [LAB-TF-08 — Terraform AWS VPC & Bastion Mimarisi](day3/LAB-TF-08-terraform-aws-vpc-architecture.md)

-   :material-kubernetes:{ .lg .middle } **Kubernetes & GitOps**

    ---

    Pod, Deployment, Service, Ingress, ConfigMap, Secret, StatefulSet, Helm chart paketleme ve Argo CD GitOps senkronizasyonu.

    - [LAB-K8S-01 — Pods & Deployments & Kubectl Cheat Sheet](day4/LAB-K8S-01-kind-pods-deployments.md)
    - [LAB-K8S-02 — Services, ConfigMaps ve Secrets](day4/LAB-K8S-02-services-config-secrets.md)
    - [LAB-K8S-03 — Production Workloads & Rolling Update](day4/LAB-K8S-03-production-workloads.md)
    - [LAB-HLM-01 — Helm Chart Mimarisi ve Dağıtımı](day4/LAB-HLM-01-helm-chart-deployment.md)
    - [LAB-ARG-01 — Argo CD ile GitOps Sürekli Teslimatı](day4/LAB-ARG-01-argocd-gitops-sync.md)

-   :material-radar:{ .lg .middle } **Gözlemlenebilirlik & Olay Müdahalesi**

    ---

    Prometheus metrik toplama, PromQL sorguları, Grafana panoları, Alertmanager kuralları, ELK Stack ve K8s CrashLoop postmortem.

    - [LAB-MON-01 — Prometheus & Grafana Metrikleri](day5/LAB-MON-01-prometheus-grafana-metrics.md)
    - [LAB-MON-02 — Alertmanager ve Bildirim Kuralları](day5/LAB-MON-02-alertmanager-rules.md)
    - [LAB-LOG-01 — Merkezi Loglama Mimarisi](day5/LAB-LOG-01-centralized-logging.md)
    - [LAB-LOG-02 — Enterprise ELK Stack Merkezi Loglama](day5/LAB-LOG-02-elk-centralized-logging.md)
    - [LAB-INC-01 — K8s CrashLoop Olay Müdahalesi (Postmortem)](day5/LAB-INC-01-k8s-crashloop-postmortem.md)

</div>

---

## 🏆 Uçtan Uca Capstone ve Gerçek Dünya Senaryoları

- **[LAB-CAP-01 — End-to-End DevOps Capstone](day5/LAB-CAP-01-end-to-end-devops.md):** Kaynak koddan Kubernetes üretimine kadar Git, Docker, CI/CD, Helm, Argo CD ve Monitoring entegrasyonu.
- **[Projeler Kataloğu](projects/05_PROJECT_CATALOG.md):** Gerçek projeler üzerinde Python Flask CI/CD, GitLab DevOps Capstone ve teslimat hatları.
- **[Sorun Giderme Senaryoları](troubleshooting/07_TROUBLESHOOTING_SCENARIOS.md):** Port çakışmaları, OOMKilled, ImagePullBackOff, CrashLoopBackOff ve network isolation çözümleri.
- **[Port & Kaynak Matrisi](reference/13_RESOURCE_AND_PORT_MATRIX.md):** Tüm lab bileşenlerinin port ve kaynak gereksinimleri.

---

## 🛠️ Laboratuvar Çalışma Standardı

Tüm laboratuvarlar standartlaştırılmış çalışma kurallarına sahiptir:

1. **İzole Çalışma Dizinleri:** Her lab `~/labs/<LAB-ID>` dizininde çalışır.
2. **ZIP Dosyaları:** Her lab sayfasının üstünde başlangıç kodlarını içeren `[İndir (ZIP)]` butonu bulunur (öğrenci paketlerinde çözüm dosyası yer almaz).
3. **Otomatik Doğrulama:** Çalışmanızı tamamladığınızda terminalde `bash scripts/validate.sh` komutunu çalıştırarak çözümünüzü test edebilirsiniz.
4. **Temizlik:** Ortamı sıfırlamak için `bash scripts/cleanup.sh` komutunu kullanabilirsiniz.
5. **İnteraktif Senaryolar:** Lab sayfalarının sonundaki interaktif soruları çözüp *"💡 Çözümü Göster"* kutucuklarına tıklayarak bilginizi pekiştirebilirsiniz.
