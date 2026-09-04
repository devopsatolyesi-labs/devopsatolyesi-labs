# DevOps Atölyesi Eğitim Lab Planı

Bu belge Labs portalındaki içerik çalışmalarının tek yol haritasıdır. Öğrenci
navigasyonu konu bazlıdır; lablar günlere göre gösterilmez.

## 1. Lab İçerik Standardı

Her yayınlanmış lab aşağıdaki kuralları sağlamadan **hazır** sayılmaz:

1. Başka bir labın dosyasına veya tamamlanmış olmasına bağımlı olmaz.
2. Standart çalışma dizini `~/labs/<LAB-ID>` olur.
3. Amaç kısa yazılır; uzun senaryo ve eğitim planlama metadatası öğrenciye gösterilmez.
4. Gerekli araçlar ve ön kontrol komutları labın içinde bulunur.
5. Gerekli tüm kaynak dosyaları web sayfasında `cat <<EOF` ile oluşturulabilir.
6. Web sayfası ve ZIP aynı kanonik `starter/` ve `scripts/` dosyalarından üretilir.
7. ZIP yalnız `README.md`, `starter/`, `scripts/` ve `images/` içerir; `solution/` içermez.
8. Scriptin adı yazılıyorsa içeriği web sayfasında da gösterilir.
9. Beklenen çıktı, doğrulama, kısa ipucu ve güvenli temizlik komutu bulunur.
10. Teknik diyagram portalda render edilir; gerektiğinde kaynak kontrollü SVG/PNG kullanılır.

## 2. Kalite Kapıları

Bir labın durumu yalnız şu sırayla ilerler:

- `draft`: içerik ve dosyalar hazırlanıyor.
- `content-ready`: web/ZIP eşitliği ve statik kontroller geçti.
- `runtime-tested`: temiz Ubuntu lab makinesinde kurulum, uygulama, doğrulama ve temizlik geçti.
- `published`: doğru eğitim grubuyla canlı portal testi geçti.

“Dosya var” veya “script syntax geçti” sonucu runtime testi yerine kullanılmaz.

## 3. DevOps Practitioner Lab Kataloğu

### Temeller

| Lab | Konu | İşlem |
|---|---|---|
| `LAB-LNX-01` | Linux preflight, süreç, servis, port ve log inceleme | Mevcut lab sadeleştirilecek |
| `LAB-GIT-01` | Repo, branch, merge, conflict ve tag | Mevcut lab bağımsızlaştırılacak |

### Docker ve Container

| Lab | Konu | İşlem |
|---|---|---|
| `LAB-DOC-01` | Container lifecycle: run, ps, logs, inspect, exec, stop, start, rm | Mevcut lab yeniden düzenlenecek |
| `LAB-DOC-02` | Environment, bind mount, named volume ve veri kalıcılığı | Mevcut lab yeniden düzenlenecek |
| `LAB-DOC-03` | Python API için Dockerfile, build, tag ve run | Mevcut lab Python odaklı düzeltilecek |
| `LAB-DOC-04` | Node.js API, layer cache, multi-stage ve non-root | Mevcut lab Node.js uygulamasına uyarlanacak |
| `LAB-DOC-05` | Bağımsız Compose: frontend, API, PostgreSQL, Redis | Mevcut lab tamamlanacak |
| `LAB-DOC-06` | Trivy taraması ve private Harbor push/pull | Mevcut lab tamamlanacak |
| `LAB-DOC-07` | Java Spring Boot uygulamasını multi-stage dockerize etme | Yeni lab |
| `LAB-DOC-08` | Statik frontend build ve Nginx runtime imajı | Yeni lab |
| `LAB-DOC-09` | User-defined network, DNS ve servisler arası iletişim | Yeni lab |
| `LAB-DOC-10` | Image katmanları, cache, tag, save/load ve temizlik | Yeni lab |
| `LAB-DOC-13` | Production Compose: healthcheck, profile, override ve resource limit | Mevcut ileri lab sadeleştirilecek |

### CI/CD ve Güvenlik

| Lab | Konu | İşlem |
|---|---|---|
| `LAB-JNK-01` | Bağımsız Python uygulamasıyla Jenkins Declarative Pipeline | Mevcut lab tamamlanacak |
| `LAB-JNK-02` | Jenkins, test, SonarQube, Trivy ve Harbor kalite kapıları | Mevcut lab bağımsızlaştırılacak |
| `LAB-GLB-01` | Bağımsız uygulamayla GitLab CI pipeline | Mevcut lab tamamlanacak |
| `LAB-GHA-01` | GitHub Actions test, image build ve registry publish | Yeni lab |

### Infrastructure as Code

| Lab | Konu | İşlem |
|---|---|---|
| `LAB-TF-01` | Terraform Docker provider ve state lifecycle | Mevcut lab bağımsızlaştırılacak |
| `LAB-TF-04` | Terraform ile Helm release ve monitoring kurulumu | Mevcut lab bağımsızlaştırılacak |
| `LAB-TF-08` | AWS VPC mimarisi; maliyetsiz plan/local test | Mevcut lab güvenli hale getirilecek |

### Kubernetes ve GitOps

| Lab | Konu | İşlem |
|---|---|---|
| `LAB-K8S-01` | kind cluster, Pod ve Deployment | Mevcut lab bağımsızlaştırılacak |
| `LAB-K8S-02` | Service, ConfigMap ve Secret | Mevcut lab bağımsızlaştırılacak |
| `LAB-K8S-03` | Probe, rollout, resource ve PVC | Mevcut lab bağımsızlaştırılacak |
| `LAB-HLM-01` | Uygulamayı Helm chart olarak paketleme | Mevcut lab bağımsızlaştırılacak |
| `LAB-ARG-01` | Argo CD sync, drift ve self-heal | Mevcut lab bağımsızlaştırılacak |

### Gözlemlenebilirlik ve Olay Yönetimi

| Lab | Konu | İşlem |
|---|---|---|
| `LAB-MON-01` | Uygulama metrikleri, Prometheus ve Grafana | Mevcut lab tamamlanacak |
| `LAB-MON-02` | Alert rule ve Alertmanager | Mevcut lab bağımsızlaştırılacak |
| `LAB-LOG-01` | Elasticsearch, Logstash, Kibana ve uygulama logu | Mevcut lab bağımsızlaştırılacak |
| `LAB-LOG-02` | İleri log toplama ve dashboard | Mevcut lab sadeleştirilecek |
| `LAB-OTEL-01` | OpenTelemetry trace, metric ve log temeli | Yeni lab |
| `LAB-INC-01` | Kubernetes olay müdahalesi ve kısa postmortem | Mevcut lab bağımsızlaştırılacak |

### Capstone ve Mini Projeler

| Proje | Kapsam | İşlem |
|---|---|---|
| `LAB-CAP-01` | Koddan CI, Harbor, kind, GitOps ve gözlemlenebilirliğe uçtan uca akış | Yeniden hazırlanacak |
| `devops-capstone-starter` | Öğrencinin fork/clone edeceği GitHub başlangıç reposu | Yeni public template repo |
| `MP-RETAIL-01` | AWS Retail Store Sample App | Yeni mini proje |
| `MP-BOUTIQUE-01` | Google Online Boutique | Yeni mini proje |
| `MP-HOTEL-01` | Hotel Reservation | Yeni mini proje |

## 4. Docker and Kubernetes Eğitim Paketi

Bu paket DevOps Practitioner paketinden ayrı tutulur. Öğrenci yalnız aşağıdaki
konu bazlı labları görür:

- Docker lifecycle ve exec: `LAB-DOC-01`
- Volume, bind mount ve environment: `LAB-DOC-02`
- Python uygulaması image build: `LAB-DOC-03`
- Docker network ve servis keşfi: `LAB-DOC-09`
- Bağımsız çok servisli Compose: `LAB-DOC-05`
- kind, Pod ve Deployment: `LAB-K8S-01`
- Service, ConfigMap ve Secret: `LAB-K8S-02`
- Probe, rollout, resource ve PVC: `LAB-K8S-03`

Java, Node.js, frontend, Harbor security ve ileri Compose labları DevOps
Practitioner paketinde kalır; eğitim ihtiyacına göre admin tarafından ayrıca
atanabilir.

## 5. Uygulama Sırası

1. **Portal temeli:** rol bazlı menü, kursa özel ortam hazırlığı, güvenli ZIP,
   web/ZIP eşitliği, `~/labs` standardı ve Mermaid render.
2. **Docker çekirdeği:** `LAB-DOC-01`, `02`, `03`, `09`, `05`.
3. **Docker çoklu dil ve güvenlik:** `LAB-DOC-04`, `06`, `07`, `08`, `10`, `13`.
4. **CI/CD:** Jenkins, GitLab CI ve GitHub Actions.
5. **IaC, Kubernetes ve GitOps:** Terraform, kind, Helm ve Argo CD.
6. **Observability:** Prometheus, Grafana, ELK/Kibana ve OpenTelemetry.
7. **Capstone:** eksiksiz starter repo ve uçtan uca çalışma.
8. **Mini projeler:** Retail, Online Boutique ve Hotel Reservation.
9. **Tam kabul testi:** iki ayrı kullanıcıyla menü, indirme, runtime ve temizlik.

Bir faz bitmeden sonraki fazdaki lablar `published` yapılmaz.

## 6. Hakan Bayraktar Kaynak Proje Envanteri

Bu kaynaklar doğrudan kopyalanmaz. Uygulama kodu güncel sürümlere yükseltilir,
gereksiz bileşenler çıkarılır ve bu belgedeki bağımsız lab standardına uyarlanır.
Her uyarlamada asıl kaynak bağlantısı labın “Kaynak” bölümünde korunur.

| Kaynak | Eğitimde Kullanım | Hedef |
|---|---|---|
| [jenkins-ci-cd-lab](https://github.com/hakanbayraktar/jenkins-ci-cd-lab) | Python uygulaması, Jenkins CI/CD, Nexus ve kind yapısından sade senaryolar | `LAB-JNK-01`, `LAB-JNK-02`, `LAB-CAP-01` |
| [github-actions-demo](https://github.com/hakanbayraktar/github-actions-demo) | Test, cache, matrix ve deployment workflow örnekleri | `LAB-GHA-01` |
| [ci-cd-docker](https://github.com/hakanbayraktar/ci-cd-docker) | Küçük Node.js uygulaması ve container CI | `LAB-DOC-04`, `LAB-GHA-01` |
| [jenkins-node](https://github.com/hakanbayraktar/jenkins-node) | Node.js test, Dockerfile ve Jenkinsfile | `LAB-DOC-04`, `LAB-JNK-01` alternatif uygulaması |
| [flask-monitoring](https://github.com/hakanbayraktar/flask-monitoring) | Flask, Jenkins, Kubernetes ve monitoring akışı | `LAB-JNK-02`, `LAB-MON-01` |
| [argocd-python](https://github.com/hakanbayraktar/argocd-python) | Küçük Python uygulaması, image workflow ve Argo CD manifestleri | `LAB-ARG-01` |
| [ArgoCD-Basics-To-Production](https://github.com/hakanbayraktar/ArgoCD-Basics-To-Production) | Sync, prune, self-heal, project, hook, wave ve Helm örnekleri | `LAB-ARG-01`, ileri GitOps labları |
| [github-kubernetes](https://github.com/hakanbayraktar/github-kubernetes) | Node.js uygulaması, GitHub Actions ve Kubernetes deployment | `LAB-GHA-01`, `LAB-K8S-01` |
| [AI-BankApp-DevOps](https://github.com/hakanbayraktar/AI-BankApp-DevOps) | Spring Boot, Compose, CI/CD ve Kubernetes için sadeleştirilecek uygulama | `LAB-DOC-07`, `LAB-CAP-01` |
| [spring-boot-course](https://github.com/hakanbayraktar/spring-boot-course) | Küçük Spring Boot API başlangıç kodu | `LAB-DOC-07` |
| [aws-vpc-terraform](https://github.com/hakanbayraktar/aws-vpc-terraform) | VPC modüllerinin maliyetsiz `fmt`, `validate` ve `plan` çalışması | `LAB-TF-08` |
| [retail-store-sample-app](https://github.com/hakanbayraktar/retail-store-sample-app) | Büyük uygulamayı hazır servis olarak kullanarak container/GitOps/observability mini projesi | `MP-RETAIL-01` |

### Medium İçeriklerinden Uyarlanacak Konular

| Kaynak | Uyarlama |
|---|---|
| [Docker Commands Cheat Sheet](https://hbayraktar.medium.com/docker-commands-cheat-sheet-with-examples-d9a26396cb6f) | Komut listesi yerine çalışan lifecycle ve image yönetimi görevleri: `LAB-DOC-01`, `LAB-DOC-10` |
| [Flask, Jenkins ve Kubernetes](https://hbayraktar.medium.com/deploying-a-flask-application-with-jenkins-to-a-kubernetes-cluster-4aa7b78d5817) | Güncel Jenkins pipeline, immutable image ve kind hedefi: `LAB-JNK-02` |
| [Modern CI/CD ve Auto-Healing](https://hbayraktar.medium.com/deployment-is-not-enough-how-to-build-a-modern-ci-cd-pipeline-with-auto-healing-infrastructure-8a04d3f737b2) | Cloud maliyeti oluşturmayan yerel Capstone kabul kriterleri: `LAB-CAP-01` |
| [Container Runtime ve Image Troubleshooting](https://hbayraktar.medium.com/production-troubleshooting-guide-3-container-runtime-image-troubleshooting-ee5499e3a8c3) | Kısa arıza kartları ve kanıt komutları: Docker/Kubernetes troubleshooting labları |
| [CI/CD, GitOps ve Helm Troubleshooting](https://hbayraktar.medium.com/production-troubleshooting-guide-4-ci-cd-gitops-helm-and-deployment-troubleshooting-c1b582baa313) | Commit → image → Helm → Argo CD iz sürme görevi: `LAB-INC-01` |
| [ASP.NET Core Dockerization](https://hbayraktar.medium.com/how-to-dockerize-a-net-8-asp-net-core-web-application-b15f63246535) | İsteğe bağlı çoklu dil containerization labı; güncel LTS sürümle yeniden yazılacak |
| [AI Kubernetes Troubleshooting Lab](https://hbayraktar.medium.com/ai-powered-kubernetes-troubleshooting-a-hands-on-agent-lab-for-junior-devops-engineers-875ae7c8a8a0) | DevOps Practitioner sonrası isteğe bağlı mini proje |

### Kaynak Kabul Kriteri

Bir kaynak yalnız şu kontrollerden sonra kataloğa alınır:

1. Lisans ve kaynak bağlantısı belirtilir.
2. Bağımlılık ve image sürümleri sabitlenir.
3. Cloud kaynağı zorunluysa yerel veya `plan-only` alternatif sağlanır.
4. Secret, gerçek hesap ve kişisel path temizlenir.
5. Temiz Ubuntu makinesinde setup, validate ve cleanup geçer.
6. Web sayfası ve öğrenci ZIP’i aynı dosyalardan üretilir.
