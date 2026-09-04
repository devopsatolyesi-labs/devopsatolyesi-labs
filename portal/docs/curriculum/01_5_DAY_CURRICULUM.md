# 01 — 5-GÜNLÜK DEVOPS PRACTITIONER EĞİTİM MÜFREDATI

## 1. Genel Bakış ve Pedagojik Model

Bu müfredat, farklı seviyelerdeki (başlangıç, orta, ileri) öğrencilerin 5 gün sonunda üretim seviyesinde (production-grade) modern DevOps süreçlerini, araçlarını ve pratiklerini tek bir Ubuntu sunucu üzerinde uçtan uca uygulayabilmesini hedefler.

### Öğretim Metodolojisi: LEARN → SEE IT → BUILD IT → VERIFY → BREAK/FIX → CHALLENGE
1. **LEARN (Teori & Zihinsel Model):** Neden-sonuç ilişkisi, endüstri standartları (DORA, CALMS, 12-Factor App, Three Ways).
2. **SEE IT (Eğitmen Referans Gösterimi):** `devopsatolyesi.com` üzerindeki çalışan merkezi platformlar (Harbor, GitLab, SonarQube, Argo CD, Grafana, Kibana vb.) incelenir.
3. **BUILD IT (Öğrenci Uygulaması):** Öğrenci kendi Ubuntu sunucusunda izole profillerle adımları birebir uygular.
4. **VERIFY (Otomasyon & Sağlama):** Öğrenci curl, inspect, test ve validation scriptleriyle sonucu doğrular.
5. **BREAK/FIX (Gerçek Hata Çözümü):** Kasıtlı enjekte edilen arızalar (port çakışması, sertifika hatası, CrashLoopBackOff, OOMKilled vb.) teşhis ve tamir edilir.
6. **CHALLENGE (İleri Seviye Görev):** Hızlı bitiren öğrenciler için optimizasyon, güvenlik sıkılaştırma ve ileri konfigürasyon görevleri verilir.

---

## 2. Günlük Zaman Çizelgesi ve Modül Dağılımı

### GÜN 1: DevOps Temelleri, Linux, Git ve Docker Giriş
* **Tema:** Siloları yıkmak, geliştirici ortamı hazırlığı, versiyon kontrol disiplini ve konteyner dünyasına ilk adım.
* **Öğrenci Profili:** `profile: docker` (RAM İhtiyacı: ~1.5 GB)

| Saat | Tür | Konu / Lab | Seviye | Çıktı & Hedef |
|---|---|---|---|---|
| **09:30 - 10:45** | Teori | DevOps Nedir? Silolar, Handoffs, Geri Bildirim Döngüleri, CALMS, Three Ways, Agile/Lean | CORE | Zihinsel model, DORA metrikleri (Deployment Frequency, Lead Time, MTTR, Change Failure Rate) |
| **10:45 - 11:00** | Ara | Kahve Molası | - | - |
| **11:00 - 12:00** | Teori & Lab | Linux Sistem Temelleri & Preflight Kontrolleri (`LAB-LNX-01`) | CORE | Systemd servisleri, port kontrolü (`ss`, `lsof`), processler (`top`, `ps`), disk/RAM kontrolü |
| **12:00 - 13:00** | Lab | Git Sürüm Kontrolü, Branching Stratejileri, Merge Çakışmaları ve PR/MR Mantığı (`LAB-GIT-01`) | CORE | Trunk-based vs GitFlow, `git commit`, `merge conflict` çözümü, detached HEAD tamiri |
| **13:00 - 14:00** | Ara | Öğle Yemeği | - | - |
| **14:00 - 15:15** | Teori | Konteyner Teknolojileri Neden Doğdu? VM vs Container, OCI Standartları, Docker Mimarisi | CORE | Docker daemon, containerd, runc, cgroups, namespaces, image layers mantığı |
| **15:15 - 16:15** | Lab | Docker Kurulum Doğrulama, İlk Konteyner, Port Yönlendirme ve Loglar (`LAB-DOC-01`) | CORE | `docker run`, port mapping (`-p`), detached mode (`-d`), logs (`--tail`, `-f`), exit kodları |
| **16:15 - 16:30** | Ara | Kahve Molası | - | - |
| **16:30 - 17:30** | Lab | Konteyner Yaşam Döngüsü, `exec`, Ortam Değişkenleri ve Volume Kalıcılığı (`LAB-DOC-02`) | CORE | Ephemeral vs Persistent storage, Named Volumes, Bind Mounts, `docker exec`, environment vars |
| **17:30 - 18:00** | Recap/QA | Günün Özeti, SEE IT Referansı, Preflight Doğrulaması ve Challenge Tanıtımı | ALL | Gün sonu durum kontrolü, soru-cevap |

---

### GÜN 2: Docker Mühendisliği, Güvenlik ve Çok Katmanlı Uygulamalar
* **Tema:** Üretim kalitesinde imaj üretimi, multi-stage build, güvenlik taraması, Harbor registry ve Compose orkestrasyonu.
* **Öğrenci Profili:** `profile: docker` + `profile: harbor` (RAM İhtiyacı: ~3.0 GB)

| Saat | Tür | Konu / Lab | Seviye | Çıktı & Hedef |
|---|---|---|---|---|
| **09:30 - 10:45** | Teori & Lab | Dockerfile Yazımı, Layer Caching, `.dockerignore` ve Optimizasyon (`LAB-DOC-03`) | CORE | Katman önbelleği sırası, gereksiz dosyaları engelleme, imaj boyutu düşürme |
| **10:45 - 11:00** | Ara | Kahve Molası | - | - |
| **11:00 - 12:30** | Lab | Multi-Stage Build, Non-Root Kullanıcı ve İmaj Sıkılaştırma (`LAB-DOC-04`) | PRACTITIONER | Python/Node.js/Java ile build vs runtime ayrımı, distroless imaj, non-root user (`UID 10001`) |
| **12:30 - 13:00** | Teori | Konteyner Güvenliği, CVE Taraması, SBOM ve Özel İmaj Kayıtçıları (Registry) | PRACTITIONER | CVE kavramı, supply chain security, Trivy taraması, Harbor private registry |
| **13:00 - 14:00** | Ara | Öğle Yemeği | - | - |
| **14:00 - 15:30** | Lab | Trivy ile Güvenlik Taraması & Harbor Private Registry Entegrasyonu (`LAB-DOC-06`) | PRACTITIONER | `trivy image --severity HIGH,CRITICAL`, Harbor push/pull, image tag immutability |
| **15:30 - 15:45** | Ara | Kahve Molası | - | - |
| **15:45 - 17:15** | Lab & Proje | Docker Compose ile Çok Katmanlı Uygulama & Healthcheck (`LAB-DOC-05` & `PROJECT-01`) | PRACTITIONER | API + DB (PostgreSQL) + Redis, `depends_on: condition: service_healthy`, bridge network |
| **17:15 - 18:00** | Challenge | Docker Break/Fix Senaryoları & Distroless/SBOM Challenge (`LAB-DOC-07`, `LAB-DOC-08`) | CHALLENGE | Port conflict, disk space dolması, rootless container, syft/cosign SBOM |

---

### GÜN 3: CI/CD Otomasyonu, Kalite & Güvenlik Kapıları, Terraform Giriş
* **Tema:** Sürekli Entegrasyon (CI), Jenkins Pipeline, GitLab CI/CD, SonarQube Quality Gate ve Kod Olarak Altyapı (IaC).
* **Öğrenci Profili:** `profile: secure-ci` (Jenkins + Sonar + Harbor) VEYA `profile: gitlab-ci` (GitLab + Runner) (RAM İhtiyacı: ~4.5 GB)

| Saat | Tür | Konu / Lab | Seviye | Çıktı & Hedef |
|---|---|---|---|---|
| **09:30 - 10:45** | Teori | CI/CD Kavramları, Continuous Integration vs Delivery vs Deployment, Pipeline Mimarisi | CORE | Otomatik testler, artefakt üretimi, feedback döngüsü, Jenkins vs GitLab CI karşılaştırması |
| **10:45 - 11:00** | Ara | Kahve Molası | - | - |
| **11:00 - 12:30** | Lab | Jenkins Declarative Pipeline: Git Checkout, Build & Test (`LAB-JNK-01`) | CORE | `Jenkinsfile`, agent docker, stages, steps, post actions (always, failure, success) |
| **12:30 - 13:00** | Teori & Demo | SonarQube Statik Kod Analizi, Clean Code ve Quality Gate Mantığı | PRACTITIONER | Kod kalitesi, kod kokuları, güvenlik açıkları, test coverage, Quality Gate kuralı |
| **13:00 - 14:00** | Ara | Öğle Yemeği | - | - |
| **14:00 - 15:30** | Lab & Proje | Güvenli Jenkins Pipeline: SonarQube + Trivy + Harbor (`LAB-JNK-02` & `PROJECT-02`) | PRACTITIONER | SonarQube Scanner, `waitForQualityGate()`, Trivy scan stage, Harbor credentials & push |
| **15:30 - 15:45** | Ara | Kahve Molası | - | - |
| **15:45 - 16:45** | Lab | Alternatif CI: GitLab CI/CD Pipeline, Runner & Container Registry (`LAB-GLB-01` & `PROJECT-03`) | PRACTITIONER | `.gitlab-ci.yml`, stages, artifacts, caching, CI variables, container scanning |
| **16:45 - 17:45** | Lab | Terraform Temelleri: Docker Provider ile Deklaratif Altyapı (`LAB-TF-01` & `PROJECT-04`) | CORE | `init`, `plan`, `apply`, `destroy`, `variables.tf`, `outputs.tf`, state file ve drift |
| **17:45 - 18:00** | Recap/QA | CI Pipeline Doğrulamaları ve Günün İncelemesi | ALL | Başarılı build artefaktları, güvenlik raporları incelemesi |

---

### GÜN 4: Kubernetes Orkestrasyonu, Helm Paketleme ve Argo CD ile GitOps
* **Tema:** Bulut yerel konteyner orkestrasyonu, kind cluster, Kubernetes nesneleri, Helm ve GitOps sürekli dağıtımı.
* **Öğrenci Profili:** `profile: kubernetes` (kind + Argo CD + Headlamp) (RAM İhtiyacı: ~4.0 GB)

| Saat | Tür | Konu / Lab | Seviye | Çıktı & Hedef |
|---|---|---|---|---|
| **09:30 - 10:45** | Teori | Kubernetes Mimarisi: Control Plane (API, etcd, sched, c-m) vs Worker Nodes (kubelet, proxy) | CORE | Neden Kubernetes? Deklaratif vs imperatif yaklaşım, Pod yaşam döngüsü, kind mimarisi |
| **10:45 - 11:00** | Ara | Kahve Molası | - | - |
| **11:00 - 12:15** | Lab | kind Cluster Kurulumu, kubectl Preflight, Pod ve Deployment Yönetimi (`LAB-K8S-01`) | CORE | `kind create cluster`, `kubectl get/describe/logs`, ReplicaSet, Deployment self-healing |
| **12:15 - 13:00** | Lab | Kubernetes Ağ ve Yapılandırma: Services, ConfigMaps ve Secrets (`LAB-K8S-02`) | CORE | ClusterIP, NodePort, LoadBalancer mantığı, ConfigMap/Secret inject etme |
| **13:00 - 14:00** | Ara | Öğle Yemeği | - | - |
| **14:00 - 15:30** | Lab | Üretim Seviyesi İş Yükleri: Resources, Probes, Rollouts ve PVC Kalıcı Depolama (`LAB-K8S-03`) | PRACTITIONER | `requests/limits`, `livenessProbe/readinessProbe`, zero-downtime rolling update, rollback |
| **15:30 - 15:45** | Ara | Kahve Molası | - | - |
| **15:45 - 16:45** | Lab | Helm ile Paket Yönetimi: Chart Yapısı, Custom Values ve Release (`LAB-HLM-01`) | PRACTITIONER | `Chart.yaml`, `values.yaml`, templates, `helm install/upgrade/rollback`, local repo |
| **16:45 - 17:45** | Lab & Proje | GitOps Devrimi: Argo CD ile Deklaratif Senkronizasyon ve Drift Detection (`LAB-ARG-01` & `PROJECT-06`) | PRACTITIONER | GitOps prensipleri, Argo CD Application, Self-heal, Git revert ile rollback |
| **17:45 - 18:00** | Challenge | K8s İleri Seviye: HPA, NetworkPolicy ve Headlamp Dashboard İncelemesi (`LAB-K8S-04`) | CHALLENGE | Auto-scaling, pod izolasyonu, Headlamp Kubernetes UI |

---

### GÜN 5: Gözlemlenebilirlik (Observability), Olay Yönetimi ve Uçtan Uca Capstone
* **Tema:** Metrikler, loglar, alarmlar, arıza simülasyonu, problem çözme (Break/Fix) ve büyük final projesi.
* **Öğrenci Profili:** `profile: monitoring` + `profile: logging` (Aşamalı / Phased Capstone) (RAM İhtiyacı: ~4.5 GB)

| Saat | Tür | Konu / Lab | Seviye | Çıktı & Hedef |
|---|---|---|---|---|
| **09:30 - 10:45** | Teori | Observability 3 Sütunu: Metrics, Logs, Traces. Golden Signals, Push vs Pull Mimarisi | CORE | Prometheus mimarisi, TSDB, Exporterlar, PromQL temelleri, Grafana veri kaynakları |
| **10:45 - 11:00** | Ara | Kahve Molası | - | - |
| **11:00 - 12:15** | Lab & Proje | Prometheus & Grafana ile Metrik Toplama ve Dashboard Oluşturma (`LAB-MON-01` & `PROJECT-07`) | PRACTITIONER | Node Exporter + App `/metrics`, PromQL sorguları (`rate()`, `histogram_quantile`), Grafana panelleri |
| **12:15 - 13:00** | Lab | Prometheus Alertmanager: Kritik Alarm Tanımları & Bildirim Mekanizması (`LAB-MON-02`) | PRACTITIONER | Alerting rules (High Latency, High CPU, Pod Crash), Alertmanager yönlendirme |
| **13:00 - 14:00** | Ara | Öğle Yemeği | - | - |
| **14:00 - 15:15** | Lab & Proje | Temel Merkezi Loglama: Nginx → Filebeat → Logstash → Elasticsearch → Kibana (`LAB-LOG-01` & `PROJECT-08`) | PRACTITIONER | Manuel Nginx pipeline, Grok, mapping, ILM, Persistent Queue, Kibana Data View ve KQL |
| **Opsiyonel 150 dk** | Challenge Lab | İleri ELK2 gözlemlenebilirliği (`LAB-LOG-02`) | CHALLENGE | Manuel Vector, Metricbeat ve Filebeat; Linux/Docker/Kubernetes telemetrisi, GeoMap, birleşik dashboard ve Canvas |
| **15:15 - 16:15** | Lab & Proje | War Room Simülasyonu: K8s Arıza Teşhisi, Hata Ayıklama ve Postmortem (`LAB-INC-01` & `PROJECT-09`) | PRACTITIONER | CrashLoopBackOff, ImagePullBackOff, OOMKilled, NetworkPolicy engeli, Root Cause Analizi |
| **16:15 - 16:30** | Ara | Kahve Molası | - | - |
| **16:30 - 17:45** | Final Capstone | BÜYÜK FİNAL: Git → CI → Sonar → Trivy → Harbor → GitOps → Argo CD → K8s → Monitoring (`PROJECT-10`) | CAPSTONE | 5 günün tüm parçalarını birleştiren tam otomatik DevOps boru hattı teslimi |
| **17:45 - 18:00** | Kapanış | Eğitim Değerlendirmesi, Sertifikasyon Yol Haritası ve Mezuniyet | ALL | DevSecOps / SRE kariyer rehberi, kaynaklar ve kapanış |

---

## 3. Gün Sonu Öğrenci Beklenen Durum Matrisi (Daily Acceptance State)

| Gün | Beklenen Öğrenci Durumu (Artifacts & System State) | Doğrulama Komutu / Kanıt |
|---|---|---|
| **Gün 1** | Temiz Docker kurulumu, çalışan ilk web konteyneri, Git repository'si, volume persistence kanıtı | `docker ps`, `curl -f http://localhost:8080`, `git status` |
| **Gün 2** | Çok aşamalı optimize Dockerfile, taranmış ve Harbor'a aktarılmış güvenli imaj, Compose ile çalışan DB+API | `trivy image`, `docker compose ps`, `curl http://localhost:8080/health` |
| **Gün 3** | Çalışan Jenkins/GitLab pipeline, SonarQube Passed Quality Gate, Harbor'da imzalı imaj, Terraform plan/apply | Jenkins/GitLab Console "SUCCESS", `terraform show` |
| **Gün 4** | Çalışan kind k8s cluster, Argo CD üzerinde Healthy & Synced microservice, Ingress/Service erişimi | `kubectl get pods -A`, `argocd app get <app>`, `curl http://app.local` |
| **Gün 5** | Grafana dashboardları (CPU/RAM/RPS), Kibana'da log aramaları, çözülmüş incident postmortemi, uçtan uca capstone | Grafana UI, Kibana Discover, Final Capstone CI/CD & GitOps akışı |
