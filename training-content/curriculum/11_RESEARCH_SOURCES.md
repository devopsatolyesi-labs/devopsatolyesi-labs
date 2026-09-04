# 11 — 2026 ARAŞTIRMA KAYNAKLARI, SÜRÜM SABİTLEME VE DEPRECATION BULGULARI

Bu doküman, 5 günlük **DevOps Practitioner** müfredatında yer alan tüm teknolojilerin 26 Ağustos 2026 tarihi itibarıyla resmi dokümantasyonlarını, upstream depolarını, sabitlenmiş kararlı sürümlerini (Training-Stable Compatibility Pins) ve eskimiş (deprecated) yöntemlere karşı belirlenen modern standartları içerir.

---

## 1. Resmi Kaynaklar ve 2026 Sürüm Sabitleme Matrisi

| Teknoloji / Araç | Resmi Dokümantasyon / Upstream Kaynak | 26 Ağustos 2026 Upstream Durumu | Seçilen Eğitim-Uyumlu Sabit Sürüm (Training-Stable Pin) | Tercih Nedeni & Lisans Durumu |
|---|---|---|---|---|
| **Linux Host OS** | [ubuntu.com/download/server](https://ubuntu.com/download/server) | 24.04.1 LTS (Noble Numbat) | **Ubuntu 24.04 LTS** | 5 yıllık LTS kurumsal desteği, güncel Linux 6.8+ çekirdeği, cgroups v2 varsayılan. |
| **Docker Engine** | [docs.docker.com/engine](https://docs.docker.com/engine/) | 28.0.x / 27.5.x | **Docker CE 27.5.1** | OCI runtime standartları, containerd 1.7+, BuildKit varsayılan (Apache 2.0). |
| **Docker Compose** | [docs.docker.com/compose](https://docs.docker.com/compose/) | v2.33.x / v2.32.x | **v2.32.4 (Compose V2)** | Go CLI Plugin mimarisi, V1 Python bağımlılığı tamamen kaldırıldı. |
| **kind (K8s in Docker)** | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/) | v0.32.0 / v0.30.0 | **kind v0.30.0** | Kubernetes 1.31/1.32 desteği, `kubeadm.k8s.io/v1beta4` tam uyumu (Apache 2.0). |
| **Kubernetes (k8s)** | [kubernetes.io/docs](https://kubernetes.io/docs/) | 1.34.x / 1.33.x / 1.32.x / 1.31.x | **Kubernetes v1.31.4** | `kindest/node:v1.31.4`, kurumsal kararlı N-2 desteği, test edilmiş API kararlılığı. |
| **kubectl CLI** | [kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/) | v1.33.x / v1.32.x / v1.31.x | **kubectl v1.31.4** | Kind cluster API sürümü ile birebir senkronize CLI. |
| **Helm** | [helm.sh/docs](https://helm.sh/docs/) | Helm v4.2.x / Helm v3.21.x | **Helm v3.21.0** (opsiyonel v4.2.0) | Helm 3'ün son LTS bakım sürümü. Helm 4 geçişi teori/challenge olarak işlenir. |
| **Argo CD** | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/) | v3.5.x / v3.4.x | **v3.4.2** | Argo CD 3.x jenerasyonunun en stabil sürümü. Native OCI registry desteği ve K8s 1.31 CRD'leri. |
| **Jenkins LTS** | [jenkins.io/changelog-stable](https://www.jenkins.io/changelog-stable/) | 2.568.2 LTS / 2.555.3 LTS | **Jenkins 2.568.2 LTS (Java 17/21)** | Ağustos 2026 güncel LTS sürümü. Java 17/21 zorunlu, güvenlik yamalı (MIT). |
| **GitLab CE & Runner** | [about.gitlab.com/releases](https://about.gitlab.com/releases/) | 17.9.x / 17.10.x | **GitLab CE 17.9.3** & Runner 17.9.x | 17.9.x LTS kararlı sürümü; modern `rules:`, DAG `needs:` tam destekli. |
| **Harbor Registry** | [goharbor.io/docs](https://goharbor.io/docs/) | v2.15.2 / v2.14.x | **Harbor v2.15.2** | Temmuz 2026 sürümü; güncellenmiş PostgreSQL backend, dahili Trivy v0.74 ve OCI signing. |
| **Trivy Scanner** | [aquasecurity.github.io/trivy](https://aquasecurity.github.io/trivy/) | v0.74.0 / v0.73.0 | **Trivy v0.74.0** | **Kritik:** Mart 2026 tedarik zinciri olayından sonra rotasyona uğrayan GPG anahtarlı güvenli sürüm. |
| **SonarQube** | [sonarsource.com](https://www.sonarsource.com/) | Community Build 26.8 / 24.12 | **SonarQube Community Build (26.8.0.126808-community)** | Yeni isimlendirme ve YY.MM takvim sürümleme standardı. Clean Code & Quality Gate açık kaynak imajı. |
| **Prometheus** | [prometheus.io/docs](https://prometheus.io/docs/) | 3.14.0 / 3.13.2 LTS | **Prometheus 3.13.2 LTS** | **Kritik:** Prometheus 3.x LTS serisi (Temmuz 2026 - Temmuz 2027 destekli). Yeni TSDB motoru ve OTel desteği. |
| **Alertmanager** | [prometheus.io/docs/alerting](https://prometheus.io/docs/alerting/latest/alertmanager/) | v0.34.0 / v0.33.0 | **Alertmanager v0.33.0** | API v2 standardı, UTF-8 etiket desteği ve modern webhook yönlendirme motoru. |
| **Grafana** | [grafana.com/docs](https://grafana.com/docs/) | 13.2.0 / 13.1.x | **Grafana 13.1.5** | Prometheus 3.x ile optimize veri kaynağı entegrasyonu, Golden Signals hazır şablonları. |
| **Vector Log Shipper** | [vector.dev/docs](https://vector.dev/docs/) | 0.40.x / 0.41.x | **v0.40.2-alpine** | Ultra hafif Rust tabanlı mimari, K8s metadata enrichment ve Elasticsearch 8.x bulk sink desteği. |
| **Elasticsearch & Kibana** | [elastic.co/guide](https://www.elastic.co/guide/index.html) | 8.15.x / 7.17.23 | **Elasticsearch 7.17.23** (veya 8.15.x) | Düşük bellek tüketimi (`-Xms512m -Xmx512m`) ve basit REST sorgulama için en stabil pin. |
| **PostgreSQL** | [hub.docker.com/_/postgres](https://hub.docker.com/_/postgres) | 16.4 / 16.x-alpine | **postgres:16.4-alpine** | Kararlı mikroservis ilişkisel veritabanı. |
| **Redis** | [hub.docker.com/_/redis](https://hub.docker.com/_/redis) | 7.4.x / 7.2.x-alpine | **redis:7.4-alpine** | Kararlı bellek içi önbellek ve oturum yönetimi. |
| **Terraform AWS Provider** | [registry.terraform.io/providers/hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws/) | v5.88.x / v5.80.x | **hashicorp/aws ~> 5.80.0** | Multi-AZ VPC, EIP, NAT Gateway, Security Groups ve EC2 yönetimi için stabil pin. |

---

## 3. Topluluk ve Referans Mimari Kaynakları

| Referans Makale / Mimari | Yazar / Kaynak | Bağlam & Katkı | Müfredattaki Karşılığı |
|---|---|---|---|
| **How to Build an AWS VPC with Public and Private Subnets using Terraform** | Bryant Son (Bryant Jimin Son) / [Medium](https://bryantson.medium.com/how-to-build-an-aws-vpc-with-public-and-private-subnets-using-terraform-5eac1dc69b83) | Multi-AZ VPC, DMZ Ingress katmanı, izole Private Subnetler, NAT Gateway çıkış maskelemesi ve Bastion Jump Host mimarisi. | `LAB-TF-08` & `PROJECT-04B` |

---

## 2. Eskimiş (Deprecated) Yaklaşımlar ve 2026 Güncel Standartları

| Alan | Eski / Hatalı Yaklaşım (Deprecated) | 2026 Güncel Standardı | Değişim Gerekçesi |
|---|---|---|---|
| **SonarQube Sürümleme** | `sonarqube:10.x-community` | `sonarqube:community` veya `sonarqube:26.8.0.126808-community` | SonarSource 2024 sonunda Community Edition'ı "Community Build" olarak adlandırdı ve `YY.MM` sürümlemesine geçti. |
| **Prometheus Sürümleme**| `prom/prometheus:v2.50.x` | `prom/prometheus:v3.13.2` (Prometheus 3.x LTS) | Prometheus 2.x yerini 3.x jenerasyonuna bıraktı; 3.13 LTS Temmuz 2027'ye kadar desteklenmektedir. |
| **Argo CD Sürümleme** | `argoproj/argo-cd:v2.10.x` | `argoproj/argo-cd:v3.4.2` | Argo CD 2.x EOL oldu; 3.x serisi native OCI ve K8s 1.31 uyumluluğu sunar. |
| **Helm Sürümleme** | Helm v2 / v3.12 | `Helm v3.21.0` (veya `Helm v4.2.x`) | Helm 3 son bakım evresindedir; Helm 4 geçişi başlamıştır. |
| **Trivy Tedarik Zinciri**| `trivy:v0.40 - v0.69` | `trivy:v0.74.0` | Mart 2026 supply chain saldırısı sonrası GPG anahtarları yenilenmiş v0.70+ sürümler zorunludur. |
| **kind kubeadm Patch** | `kind: InitConfiguration` (v1beta3) | `apiVersion: kubeadm.k8s.io/v1beta4` | Kubernetes 1.31+ ile birlikte kubeadm v1beta4 formatına geçilmiştir. |
| **Docker Compose** | `docker-compose` (Python V1) | `docker compose` (Go V2 CLI Plugin) | V1 kullanımdan kalktı (EOL); V2 çok daha hızlı ve Docker CLI'a gömülü. |
| **Kubernetes Ingress** | `apiVersion: extensions/v1beta1` | `apiVersion: networking.k8s.io/v1` | Eski Ingress API K8s 1.22'de tamamen kaldırıldı. |
| **Kubernetes HPA** | `apiVersion: autoscaling/v2beta2` | `apiVersion: autoscaling/v2` | Beta autoscaling sürümleri kaldırıldı; v2 stabil standarda geçildi. |
