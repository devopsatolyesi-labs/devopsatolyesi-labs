# 16 — 2026 EĞİTİM-UYUMLU SÜRÜM MATRİSİ (TRAINING-STABLE COMPATIBILITY MATRIX)

**Referans Tarih:** 26–27 Ağustos 2026  
**Hedef Ortam:** Tek Ubuntu 24.04 LTS Sunucusu (8–16 GB RAM)  
**Tasarım Prensibi:** Körü körüne "latest" veya kararsız ara sürümler yerine, **eğitimde %100 test edilmiş, karşılıklı bağımlılıkları uyumlu (cross-compatible), bellek kısıtlarına uygun ve uzun ömürlü (LTS / Stable Pin)** sürümler seçilmiştir.

---

## 1. Çekirdek Teknoloji Sürüm Sabitleme Tablosu

| Teknoloji / Bileşen | Resmi Upstream Depo / Kaynak | 26 Ağustos 2026 Güncel Durum | Seçilen Eğitim-Uyumlu Sabit Sürüm (Training-Stable Pin) | Seçim Nedeni & Uyumluluk Gerekçesi |
|---|---|---|---|---|
| **Host İşletim Sistemi** | [Ubuntu Releases](https://releases.ubuntu.com/) | 24.04.1 LTS (Noble Numbat) | **Ubuntu 24.04 LTS** | 5 yıllık kurumsal LTS, Linux 6.8+ çekirdeği, yerel `cgroups v2` tam desteği. |
| **Docker Engine (CE)** | [docker/cli](https://github.com/docker/cli) | 28.0.x / 27.5.x | **Docker CE 27.5.1** | OCI runtime kararlılığı, containerd 1.7+, BuildKit varsayılan. |
| **Docker Compose** | [docker/compose](https://github.com/docker/compose) | v2.33.x / v2.32.x | **v2.32.4 (Compose V2 Plugin)** | Go tabanlı yerel CLI eklentisi. V1 Python CLI kullanımdan tamamen kalkmıştır. |
| **Terraform (IaC)** | [HashiCorp Releases](https://releases.hashicorp.com/terraform/) | 1.16.0 / 1.15.x | **Terraform 1.16.0** | 2026 kararlı 1.x sürümü. Docker (`kreuzwerker/docker:3.0.2`), K8s ve Helm sağlayıcılarıyla geriye dönük %100 uyumludur. |
| **kind (K8s in Docker)** | [kubernetes-sigs/kind](https://github.com/kubernetes-sigs/kind) | v0.32.0 / v0.30.0 | **kind v0.30.0** | Kubernetes 1.31 desteği, `kubeadm.k8s.io/v1beta4` uyumluluğu, Envoy tabanlı Ingress yönlendirmesi. |
| **Kubernetes (k8s Node)**| [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes) | 1.34.x / 1.32.x / 1.31.x | **kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211** | Kurumsal standart 1.31 LTS hattı. SHA256 digest pini ile sürüm drifti ve beklenmedik imaj çekme hataları önlenir. |
| **kubectl CLI** | [kubernetes/kubectl](https://kubernetes.io/docs/tasks/tools/) | v1.33.x / v1.31.x | **kubectl v1.31.9** (`pkgs.k8s.io/.../v1.31/deb/`) | Kind cluster API sürümü ile birebir eşleşen kararlı CLI. |
| **Headlamp Web UI** | [kubernetes-sigs/headlamp](https://github.com/kubernetes-sigs/headlamp) | v0.45.0 (Ağustos 2026) | **ghcr.io/headlamp-k8s/headlamp:v0.45.0** | 2026 güncel upstream sürümü. Modern CRD şablonları, düşük bellek ayak izi ve K8s 1.31 entegrasyonu. |
| **Helm** | [helm/helm](https://github.com/helm/helm) | Helm v4.2.x / Helm v3.21.x | **Helm v3.21.0** (opsiyonel v4.2.0 uyumlu) | Helm 3'ün son LTS bakım sürümü. Helm 4 geçişi eğitimde anlatılırken mevcut chart ekosistemi kırılmadan korunur. |
| **Argo CD** | [argoproj/argo-cd](https://github.com/argoproj/argo-cd) | v3.5.x / v3.4.x | **v3.4.2** | Argo CD 3.x jenerasyonunun en stabil ara sürümü. Native OCI registry desteği, ApplicationSet UI ve K8s 1.31 uyumlu CRD'ler. |
| **Jenkins LTS** | [jenkins.io](https://www.jenkins.io/changelog-stable/) | 2.568.2 LTS / 2.555.3 LTS | **Jenkins 2.568.2 LTS (Java 17/21)** | Ağustos 2026 güncel LTS sürümü. Güvenlik açıkları yamalanmış, modern UI ve Pipeline eklentileriyle tam uyumlu. |
| **SonarQube** | [SonarSource](https://www.sonarsource.com/) | Community Build 26.8 / 24.12 | **sonarqube:26.8.0.126808-community** (no alias) | SonarSource'un takvim sürümleme (YY.MM) standardı. Dahili Java 17, Clean Code ve Jenkins `waitForQualityGate()` ile tam uyumlu. |
| **GitLab CE** | [gitlab.com](https://about.gitlab.com/releases/) | 17.9.x / 17.10.x | **gitlab/gitlab-ce:17.9.3-ce.0** | 17.9.x LTS kararlı sürümü; Puma bellek optimizasyonu ve DAG `needs:` tam destekli. |
| **GitLab Runner** | [gitlab.com](https://gitlab.com/gitlab-org/gitlab-runner) | alpine-v17.9.1 | **gitlab/gitlab-runner:alpine-v17.9.1** | GitLab CE 17.9.3 ile tam uyumlu resmi upstream Runner imajı. |
| **Harbor Registry** | [goharbor.io](https://github.com/goharbor/harbor) | v2.15.x / v2.14.x | **Harbor v2.15.0** | Temmuz 2026 sürümü; güncellenmiş PostgreSQL backend, dahili Trivy v0.74 desteği ve OCI Artifact imzalaması. |
| **Trivy Scanner** | [aquasecurity/trivy](https://github.com/aquasecurity/trivy) | v0.74.0 / v0.73.0 | **Trivy v0.74.0** | Mart 2026'daki tedarik zinciri olayından (v0.69.4) sonra yenilenen GPG anahtarları ve VEX/Java iyileştirmelerini içeren güvenli sürüm. |
| **Prometheus** | [prometheus/prometheus](https://github.com/prometheus/prometheus) | 3.14.0 / 3.13.2 LTS | **Prometheus 3.13.2 LTS** | Prometheus 3.x LTS serisi (Temmuz 2026 - Temmuz 2027 destekli). Yeni TSDB motoru, OpenTelemetry uyumluluğu ve PromQL optimizasyonu. |
| **Alertmanager** | [prometheus/alertmanager](https://github.com/prometheus/alertmanager) | v0.34.0 / v0.33.0 | **v0.33.0** | API v2 standardı, UTF-8 etiket desteği ve modern webhook yönlendirme motoru. |
| **Grafana** | [grafana/grafana](https://github.com/grafana/grafana) | 13.2.0 / 13.1.x | **Grafana 13.1.5** | Prometheus 3.x ile optimize veri kaynağı entegrasyonu, Golden Signals hazır şablonları. |
| **Vector Log Shipper** | [vectordotdev/vector](https://github.com/vectordotdev/vector) | 0.40.x / 0.41.x | **v0.40.2-alpine** | Ultra hafif Rust tabanlı mimari, K8s metadata enrichment ve Elasticsearch 8.x bulk sink desteği (`suppress_type_name: true`). |
| **Elasticsearch** | [elastic/elasticsearch](https://www.elastic.co/) | 9.5.2 / 8.17.8 | **docker.elastic.co/elasticsearch/elasticsearch:8.17.8** | **Kritik Sürüm Kararı:** 9.5.2 yüksek bellek (4GB+ konteyner sınırı) nedeniyle 8-16 GB RAM sunucularda OOM yaratır. 8.17.8 ise 1GB heap ile stabil çalışır, security dev modda kapatılabilir. |
| **Kibana** | [elastic/kibana](https://www.elastic.co/) | 9.5.2 / 8.17.8 | **docker.elastic.co/kibana/kibana:8.17.8** | Elasticsearch 8.17.8 ile birebir uyumlu log görselleştirme arayüzü. |
| **PostgreSQL** | [postgres](https://hub.docker.com/_/postgres) | 16.4 / 16.x-alpine | **postgres:16.4-alpine** | Kararlı mikroservis ilişkisel veritabanı. |
| **Redis** | [redis](https://hub.docker.com/_/redis) | 7.4.x / 7.2.x-alpine | **redis:7.4-alpine** | Kararlı bellek içi önbellek ve oturum yönetimi. |

---

## 2. Çapraz Uyumluluk (Cross-Component Compatibility) Doğrulamaları

### 2.1. kind v0.30.0 + Kubernetes v1.31.9 + kubeadm v1beta4
* **Durum:** Kubernetes 1.31+ ile birlikte `kubeadm` yapılandırmasında `v1beta4` formatı zorunlu hale gelmiştir.
* **Uygulama:** `kind-cluster.yaml` içinde `InitConfiguration` yaması `apiVersion: kubeadm.k8s.io/v1beta4` olarak tanımlanmıştır ve `kindest/node:v1.31.9@sha256:b94a3a6c06198d17f59cca8c6f486236fa05e2fb359cbd75dabbfc348a10b211` ile çalıştırılır.
* **Sonuç:** Küme kurulumu hatasız, ingress port yönlendirmeleri (80/443) ve Headlamp v0.45 entegrasyonu tam uyumludur.

### 2.2. GitLab CE 17.9.3 & GitLab Runner alpine-v17.9.1 Eşleşmesi
* **Durum:** GitLab mimarisinde Runner ile sunucu arasındaki API sözleşmesi major.minor serisinde tam eşleşme gerektirir.
* **Uygulama:** CE 17.9.3-ce.0 sürümüne karşılık resmi `gitlab/gitlab-runner:alpine-v17.9.1` konteyneri konuşlandırılmıştır.
* **Sonuç:** CI/CD job kayıtlarında ve Docker executor soket bağlama aşamalarında sürüm uyumsuzluğu hatası alınmaz.

### 2.3. Elasticsearch 8.17.8 + Kibana 8.17.8 + Vector 0.40.2 (RAM Kanıtı)
* **Durum:** Upstream 9.5.2 sürümü varsayılan olarak zorunlu TLS ve 2GB minimum heap talep eder; konteyner taban ayak izi Kibana ile birlikte 5.5 GB'a çıkarak 8–16 GB eğitim sunucusunu tüketir. 7.17 serisi ise EOL'dir.
* **Uygulama:** `elasticsearch:8.17.8` imajı `discovery.type=single-node`, `xpack.security.enabled=false`, `ES_JAVA_OPTS=-Xms1g -Xmx1g` ayarlarıyla yapılandırılmıştır. Vector `suppress_type_name: true` ile bulk ingestion sağlar.
* **Sonuç:** Logging profili toplamda ~2.4 GB RAM ile sorunsuz çalışır; sistem kararlılığı korunur.

### 2.4. Terraform 1.16.0 + kreuzwerker/docker 3.0.2
* **Durum:** Terraform 1.16.0, HCL2 ve modern state yönetimini desteklerken mevcut `required_version = ">= 1.5.0"` kuralına tam uyar.
* **Sonuç:** Docker container provisioning ve local orchestration lablarında hiçbir sözdizim kırılması yaşanmaz.

### 2.5. Jenkins 2.568.2 LTS + SonarQube Community Build (26.8.0.126808-community)
* **Durum:** Jenkins 2.568.2 LTS çalışmak için Java 17 gerektirir. SonarQube Community Build ise Java 17 tabanlı analizcileri destekler.
* **Sonuç:** İki araç arasındaki webhook geri bildirimi `waitForQualityGate()` ile kusursuz çalışır.

---

## 3. 7 Servis Profili ve Bellek İzolasyonu

Eğitim ortamında toplam **7 adet izole profil** tanımlanmıştır:
1. `docker` (~0.5 GB RAM)
2. `jenkins-ci` (~1.5 GB RAM)
3. `secure-ci` (~3.5 GB RAM)
4. `gitlab-ci` (~4.5 GB RAM)
5. `kubernetes` (~3.0 GB RAM)
6. `monitoring` (~1.2 GB RAM)
7. `logging` (~2.4 GB RAM)
