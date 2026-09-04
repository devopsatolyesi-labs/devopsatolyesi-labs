# 03 — ZORUNLU 5-GÜNLÜK LAB SETİ PORTAL VE UYGULAMA MASTER REHBERİ

Bu doküman, 5 günlük **DevOps Practitioner** eğitiminde her öğrencinin mutlaka tamamlaması gereken **22 adet zorunlu labın** portal navigasyonunu, hedef repo yollarını, host portlarını, profil gereksinimlerini, zaman kutularını (timebox) ve doğrulama mekanizmalarını açıklar.

Tüm zorunlu lablar, öğrenci portalında doğrudan yayınlanabilecek tamlıkta (**adım adım anlatım, tam copy/paste Ubuntu komutları, eksiksiz dosya içerikleri, beklenen çıktılar, doğrulama scriptleri, break/fix senaryoları, temizlik ve sıfırlama adımları**) hazırlanmış olup `outputs/labs/<technology>/` dizini altında bağımsız dosyalar olarak yer almaktadır.

---

## 1. 22 Zorunlu Lab Master Navigasyon ve Uygulama Matrisi

| Gün | Lab ID | Teknoloji | Seviye | Süre | Profil | Host Portları | Target Repo Path | Hedef ve Öğrenim Çıktısı | Portal Dosya Linki |
|---|---|---|---|---|---|---|---|---|---|
| **Gün 1** | `LAB-LNX-01` | Linux | CORE | 30 dk | `docker` | 22 (SSH) | `labs/LAB-LNX-01/` | Systemd servisleri, açık port analizi (`ss`), cgroups v2 ve kaynak preflight denetimi | [`labs/linux/LAB-LNX-01-linux-preflight.md`](labs/linux/LAB-LNX-01-linux-preflight.md) |
| **Gün 1** | `LAB-GIT-01` | Git | CORE | 45 dk | `docker` | - | `labs/LAB-GIT-01/` | Branching, merge conflict çözümü, PR mantığı ve temiz commit geçmişi | [`labs/git/LAB-GIT-01-git-workflow.md`](labs/git/LAB-GIT-01-git-workflow.md) |
| **Gün 1** | `LAB-DOC-01` | Docker | CORE | 30 dk | `docker` | `8080:80` | `labs/LAB-DOC-01/` | Docker Engine doğrulama, ilk container, port haritalama, log akışı ve yaşam döngüsü | [`labs/docker/LAB-DOC-01-docker-first-container.md`](labs/docker/LAB-DOC-01-docker-first-container.md) |
| **Gün 1** | `LAB-DOC-02` | Docker | CORE | 40 dk | `docker` | `5432:5432` | `labs/LAB-DOC-02/` | Ephemeral vs persistent depolama, Named Volume kalıcılığı, `docker exec`, environment vars | [`labs/docker/LAB-DOC-02-docker-volumes-env.md`](labs/docker/LAB-DOC-02-docker-volumes-env.md) |
| **Gün 2** | `LAB-DOC-03` | Docker | CORE | 45 dk | `docker` | `8000:8000` | `labs/LAB-DOC-03/` | Verimli katman sırası, `.dockerignore` ile gereksiz dosyaları atma, build cache optimizasyonu | [`labs/docker/LAB-DOC-03-dockerfile-optimization.md`](labs/docker/LAB-DOC-03-dockerfile-optimization.md) |
| **Gün 2** | `LAB-DOC-04` | Docker | PRACTITIONER | 60 dk | `docker` | `3000:3000` | `labs/LAB-DOC-04/` | Multi-stage build, sayısal non-root kullanıcı (`UID 10001`), imaj boyutu küçültme | [`labs/docker/LAB-DOC-04-docker-multistage-hardening.md`](labs/docker/LAB-DOC-04-docker-multistage-hardening.md) |
| **Gün 2** | `LAB-DOC-05` | Docker | PRACTITIONER | 60 dk | `docker` | `8080`, `5432`, `6379` | `labs/LAB-DOC-05/` | Docker Compose çok katmanlı mikroservis (API + DB + Redis), `condition: service_healthy` | [`labs/docker/LAB-DOC-05-docker-compose-multitier.md`](labs/docker/LAB-DOC-05-docker-compose-multitier.md) |
| **Gün 2** | `LAB-DOC-06` | Docker/Sec | PRACTITIONER | 60 dk | `docker` | `8082:8082` | `labs/LAB-DOC-06/` | Trivy v0.74 ile CVE taraması, CRITICAL blocker (`--exit-code 1`), Harbor v2.15 push | [`labs/docker/LAB-DOC-06-trivy-harbor-integration.md`](labs/docker/LAB-DOC-06-trivy-harbor-integration.md) |
| **Gün 3** | `LAB-JNK-01` | Jenkins | CORE | 45 dk | `secure-ci` | `8080:8080` | `labs/LAB-JNK-01/` | Declarative Pipeline as Code (`Jenkinsfile`), Git checkout, automated pytest, JUnit XML | [`labs/jenkins/LAB-JNK-01-jenkins-declarative-pipeline.md`](labs/jenkins/LAB-JNK-01-jenkins-declarative-pipeline.md) |
| **Gün 3** | `LAB-JNK-02` | Jenkins/QA | PRACTITIONER | 60 dk | `secure-ci` | `8080`, `9000`, `8082` | `labs/LAB-JNK-02/` | SonarQube Community Build analizi, `waitForQualityGate()`, Trivy CVE gate, Harbor robot push | [`labs/jenkins/LAB-JNK-02-jenkins-secure-pipeline.md`](labs/jenkins/LAB-JNK-02-jenkins-secure-pipeline.md) |
| **Gün 3** | `LAB-GLB-01` | GitLab | PRACTITIONER | 45 dk | `gitlab-ci` | `8081:80` | `labs/LAB-GLB-01/` | GitLab CI/CD stages, jobs, variables, cache vs artifacts ayrımı, Docker runner | [`labs/gitlab/LAB-GLB-01-gitlab-ci-pipeline.md`](labs/gitlab/LAB-GLB-01-gitlab-ci-pipeline.md) |
| **Gün 3** | `LAB-TF-01` | Terraform | CORE | 45 dk | `docker` | `8090:80` | `labs/LAB-TF-01/` | `kreuzwerker/docker` provider ile deklaratif IaC, state yaşam döngüsü ve drift tespiti | [`labs/terraform/LAB-TF-01-terraform-docker-provider.md`](labs/terraform/LAB-TF-01-terraform-docker-provider.md) |
| **Gün 4** | `LAB-K8S-01` | Kubernetes | CORE | 45 dk | `kubernetes` | `80:80`, `443:443` | `labs/LAB-K8S-01/` | kind v0.30 3-node cluster, kubeadm v1beta4, kubectl, Pod, Deployment ve self-healing | [`labs/kubernetes/LAB-K8S-01-kind-pods-deployments.md`](labs/kubernetes/LAB-K8S-01-kind-pods-deployments.md) |
| **Gün 4** | `LAB-K8S-02` | Kubernetes | CORE | 45 dk | `kubernetes` | - | `labs/LAB-K8S-02/` | ClusterIP/NodePort Services, CoreDNS keşfi, ConfigMap ve Secret ortam/dosya enjeksiyonu | [`labs/kubernetes/LAB-K8S-02-services-config-secrets.md`](labs/kubernetes/LAB-K8S-02-services-config-secrets.md) |
| **Gün 4** | `LAB-K8S-03` | Kubernetes | PRACTITIONER | 60 dk | `kubernetes` | - | `labs/LAB-K8S-03/` | CPU/RAM limits & requests, Liveness/Readiness probları, Zero-Downtime RollingUpdate, PVC | [`labs/kubernetes/LAB-K8S-03-production-workloads.md`](labs/kubernetes/LAB-K8S-03-production-workloads.md) |
| **Gün 4** | `LAB-HLM-01` | Helm | PRACTITIONER | 45 dk | `kubernetes` | - | `labs/LAB-HLM-01/` | Helm v3.21 Chart mimarisi, parametrik `values.yaml`, release upgrade ve rollback | [`labs/helm/LAB-HLM-01-helm-chart-deployment.md`](labs/helm/LAB-HLM-01-helm-chart-deployment.md) |
| **Gün 4** | `LAB-ARG-01` | GitOps | PRACTITIONER | 45 dk | `kubernetes` | `8085:443` | `labs/LAB-ARG-01/` | Argo CD v3.4 kurulumu, deklaratif Application CRD, otomatik sync ve drift self-healing | [`labs/gitops/LAB-ARG-01-argocd-gitops-sync.md`](labs/gitops/LAB-ARG-01-argocd-gitops-sync.md) |
| **Gün 5** | `LAB-MON-01` | Prometheus | PRACTITIONER | 45 dk | `monitoring` | `9090`, `3000`, `9100` | `labs/LAB-MON-01/` | Prometheus 3.13 LTS metrik çekme, PromQL (`rate`), Grafana 13.x Golden Signals paneli | [`labs/monitoring/LAB-MON-01-prometheus-grafana-metrics.md`](labs/monitoring/LAB-MON-01-prometheus-grafana-metrics.md) |
| **Gün 5** | `LAB-MON-02` | Alerting | PRACTITIONER | 45 dk | `monitoring` | `9090`, `9093` | `labs/LAB-MON-02/` | Alertmanager v0.33, ServiceDown alarm kuralları, deduplication ve webhook yönlendirme | [`labs/monitoring/LAB-MON-02-alertmanager-rules.md`](labs/monitoring/LAB-MON-02-alertmanager-rules.md) |
| **Gün 5** | `LAB-LOG-01` | Logging | PRACTITIONER | 45 dk | `logging` | `9200`, `5601` | `labs/LAB-LOG-01/` | Yapılandırılmış JSON log basımı, Vector 0.40 ile parse etme, Elasticsearch 7.17 bulk sink | [`labs/logging/LAB-LOG-01-centralized-logging.md`](labs/logging/LAB-LOG-01-centralized-logging.md) |
| **Gün 5** | `LAB-INC-01` | Incident | CHALLENGE | 45 dk | `kubernetes` | - | `labs/LAB-INC-01/` | War Room simülasyonu: CrashLoopBackOff, ImagePullBackOff, Probe flap onarımı ve Postmortem | [`labs/incident/LAB-INC-01-k8s-crashloop-postmortem.md`](labs/incident/LAB-INC-01-k8s-crashloop-postmortem.md) |
| **Gün 5** | `LAB-CAP-01` | Capstone | CAPSTONE | 90 dk | `phased` | `8000`, `8082` | `labs/LAB-CAP-01/` | Uçtan uca teslimat zinciri: Git commit -> Unit Test -> Sonar -> Trivy -> Harbor -> K8s -> Telemetry | [`labs/capstone/LAB-CAP-01-end-to-end-devops.md`](labs/capstone/LAB-CAP-01-end-to-end-devops.md) |

---

## 2. Öğrenci Portalı Uygulama Standartları

1. **Doğrudan Kopyalanabilir Kod Blokları:** Tüm komutlar `cat <<'EOF' > path/to/file` yapısıyla verilmiştir; öğrencinin dosyayı elle arayıp bulmasına gerek kalmaz.
2. **Çakışmasız Port Tahsisi:** Aynı profil içinde çalışan hiçbir servis aynı host portunu dinlemez.
3. **Somut Doğrulama:** Öğrencinin labı başarıyla tamamladığını doğrudan test edebileceği komutlar (`curl`, `docker ps`, `kubectl get` vb.) adım adım gösterilir.
4. **Kod Odaklı Sade Yapı:** Öğrenci gereksiz yan scriptlerle vakit kaybetmez, doğrudan uygulamanın mimarisine ve yapılandırma kodlarına odaklanır.
