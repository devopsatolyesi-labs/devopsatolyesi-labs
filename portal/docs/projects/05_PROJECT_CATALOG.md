# 05 — PROJE KATALOĞU (PROJECTS 01–10)

Bu doküman, 5 günlük **DevOps Practitioner** eğitiminde öğrencilerin öğrendiklerini pekiştirmeleri ve portfolyo seviyesinde pratik çıktılar üretmeleri için tasarlanmış **10 adet kapsamlı projenin** sınıflandırmalarını (Classifications), mimari planlarını, kilometre taşlarını (milestones), doğrulama kriterlerini ve Codex handoff spesifikasyonlarını içerir.

---

## 1. Proje Dağılım ve Sınıflandırma Matrisi

Eğitim akışının aksamaması, tek sunucu bellek sınırının (8–16 GB RAM) korunması ve farklı öğrenme hızlarındaki öğrencilerin optimum verim alması için tüm projeler 5 pedagojik sınıfa ayrılmıştır:

| Proje ID | Proje Adı | Önerilen Gün | Seviye | Süre | Profil | Proje Sınıflandırması (Classification) | Pedagojik Rolü |
|---|---|---|---|---|---|---|---|
| `PROJECT-01` | **Dockerized Multi-Tier Microservice Stack** | Gün 2 | PRACTITIONER | 90 dk | `docker` | **EMBEDDED** | Gün 2 Docker lablarının (`LAB-DOC-04/05/06`) doğal birleşimidir; ayrı bir bağlam gerektirmez. |
| `PROJECT-02` | **Enterprise Secure Jenkins CI/CD Pipeline** | Gün 3 | PRACTITIONER | 90 dk | `secure-ci` | **MANDATORY IN-CLASS** | Gün 3 sınıf içi zorunlu projedir; her öğrenci Jenkinsfile ve SonarQube kapısını tamamlar. |
| `PROJECT-03` | **Modern GitLab CI/CD GitOps Trigger Pipeline** | Gün 3 | PRACTITIONER | 90 dk | `gitlab-ci` | **INSTRUCTOR SHOWCASE** | Bellek şişmesini önlemek için eğitmen tarafından canlı gösterilir; Jenkins ile farkları incelenir. |
| `PROJECT-04` | **Terraform Local Infrastructure as Code (IaC)** | Gün 4 | PRACTITIONER | 60 dk | `docker` / `kubernetes` | **OPTIONAL-TAKE-HOME** | IaC becerilerini pekiştirmek isteyen öğrencilere ödev ve ev çalışması olarak verilir. |
| `PROJECT-04B` | **AWS Multi-AZ VPC Architecture with Terraform (Bryant Son)** | Gün 4 | PRACTITIONER | 75 dk | `docker` / `aws` | **PORTFOLIO CLOUD PROJECT** | Gerçek bulut ağ mimarisi (Public/Private Subnets, NAT GW, Bastion, EIP, Route Tables) portfolyo projesidir. |
| `PROJECT-05` | **Production-Ready Kubernetes Microservice Deployment** | Gün 4 | PRACTITIONER | 90 dk | `kubernetes` | **MANDATORY IN-CLASS** | Gün 4 sınıf içi zorunlu ana projedir; RollingUpdate, Probes, ConfigMap ve PVC bağlanır. |
| `PROJECT-06` | **Declarative GitOps Continuous Delivery with Argo CD** | Gün 4 | PRACTITIONER | 75 dk | `kubernetes` | **EMBEDDED** | Gün 4 Kubernetes çalışmalarının içine gömülüdür; GitOps döngüsünü tamamlar. |
| `PROJECT-07` | **Full-Stack Observability with Prometheus & Grafana** | Gün 5 | PRACTITIONER | 90 dk | `monitoring` | **MANDATORY IN-CLASS** | Gün 5 sabah oturumu zorunlu projesidir; metrik çekme ve Golden Signals panelleri kurulur. |
| `PROJECT-08` | **Centralized Log Analytics with Elasticsearch & Kibana** | Gün 5 | PRACTITIONER | 90 dk | `logging` | **FAST-CLASS** | İzleme projesini erken bitiren hızlı öğrencilere Vector ve Elasticsearch log analizi verilir. |
| `PROJECT-09` | **Production War Room: Multi-Failure Incident Recovery** | Gün 5 | CHALLENGE | 60 dk | `kubernetes` | **FAST-CLASS** | İleri seviye öğrenciler için 4 arızalı pod ve servis kriz ortamı simülasyonudur. |
| `PROJECT-10` | **Final Integrated Capstone: Code to Observability** | Gün 5 | CAPSTONE | 120 dk | `phased` | **MANDATORY IN-CLASS** | Eğitimin final büyük projesidir; tüm 5 günün çıktısını tek bir canlı pipeline'da birleştirir. |

---

## 2. Detaylı Proje Planları

### PROJECT-01 — Dockerized Multi-Tier Microservice Stack

#### Metadata
- **Classification:** **EMBEDDED** (Gün 2 lablarına gömülü pekiştirme)
- **Recommended Day:** Day 2
- **Level:** PRACTITIONER
- **Estimated Time:** 90 dk
- **Required Profiles:** `docker`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-01`

#### Scenario
E-Ticaret şirketi monolitik yapısını mikroservislere bölmektedir. Geliştirme ekibi Python FastAPI tabanlı bir ürün/sipariş servisi yazmıştır. Bu servisin PostgreSQL 16 veritabanı ve Redis 7.4 önbellek katmanı ile birlikte tek bir `compose.yaml` ile ayağa kaldırılması, tüm servislerin healthcheck kurallarına göre sıralı başlaması, imajların multi-stage ve non-root (`UID 10001`) olarak sıkılaştırılması ve Trivy ile taranması istenmektedir.

#### Learning Outcomes
- Multi-stage Dockerfile yazımı ve Alpine optimizasyonu
- Servis bağımlılıkları ve healthcheck (`service_healthy`) yönetimi
- İzolasyonlu Docker bridge ağları ve named volume yönetimi
- Trivy v0.74 ile zafiyet taraması ve CVE engelleme

#### Architecture
```text
                     [ Host Port: 8080 ]
                             |
                             v
               +-------------------------------+
               |   order-api (FastAPI Python)  |
               +-------------------------------+
                     |                   |
        (Port: 5432) |                   | (Port: 6379)
                     v                   v
             +---------------+   +---------------+
             |  postgres-db  |   |  redis-cache  |
             | (Volume bound)|   | (Memory-only) |
             +---------------+   +---------------+
```

#### Prerequisites
`LAB-DOC-01` ila `LAB-DOC-06` tamamlanmış olmalıdır.

#### Starter App/Repo
`outputs/labs/docker/LAB-DOC-05-docker-compose-multitier.md` içerisindeki Python ve Compose kodları.

#### Milestones
- **Milestone 1:** `app/Dockerfile` dosyasını multi-stage ve non-root (`UID 10001`) olarak yazma ve derleme.
- **Milestone 2:** `compose.yaml` dosyasında PostgreSQL ve Redis servislerini `healthcheck` kurallarıyla tanımlama.
- **Milestone 3:** `order-api` servisini `depends_on: {postgres: {condition: service_healthy}}` ile bağlama.
- **Milestone 4:** Trivy ile imajı tarayarak CRITICAL CVE olmadığını doğrulama.

#### Final Acceptance Criteria
- `curl -sf http://localhost:8080/healthz` komutu `{"status": "HEALTHY", "db": "OK", "redis": "OK"}` dönmelidir.
- Konteyner silinip `docker compose up -d` yapıldığında Redis sayaç ve DB verileri korunmalıdır.

---

### PROJECT-02 — Enterprise Secure Jenkins CI/CD Pipeline

#### Metadata
- **Classification:** **MANDATORY IN-CLASS** (Gün 3 sınıf içi zorunlu proje)
- **Recommended Day:** Day 3
- **Level:** PRACTITIONER
- **Estimated Time:** 90 dk
- **Required Profiles:** `secure-ci`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-02`

#### Scenario
Kurumsal finans kuruluşu için geliştirilen ödeme mikroservisinin CI/CD süreçleri Jenkins 2.568.2 LTS üzerinde otomatikleştirilecektir. Pipeline her Git push işleminde tetiklenecek; birim testleri koşturacak; SonarQube Community Build (26.8.0.126808) üzerinde statik analiz yapıp Quality Gate onayı alacak; Docker imajını derleyip Trivy v0.74 ile tarayacak ve güvenli imajı Harbor v2.15.2 Registry'ye aktaracaktır.

#### Learning Outcomes
- Jenkins Declarative Pipeline sintaksı (`Jenkinsfile`)
- SonarQube Clean Code kuralları ve Quality Gate kapısı (`waitForQualityGate()`)
- Shift-left container güvenlik taraması (Trivy `--exit-code 1`)
- Harbor robot hesabı ve credential binding

#### Architecture
```text
  [ Git Repo ] ---> [ Jenkins ] ---> Unit Tests ---> SonarQube Analysis
                                                           |
                                                           v
  [ Harbor Registry ] <--- Trivy Security Gate <--- Docker Multi-Stage Build
```

#### Prerequisites
`LAB-JNK-01`, `LAB-JNK-02`, `LAB-DOC-06`.

#### Starter App/Repo
`outputs/labs/jenkins/LAB-JNK-02-jenkins-secure-pipeline.md`.

#### Milestones
- **Milestone 1:** Pytest ile unit testleri ve JUnit XML raporunu üreten Jenkins stage'i.
- **Milestone 2:** SonarQube statik analizi ve `waitForQualityGate()` bloğu.
- **Milestone 3:** Docker build ve Trivy güvenlik kapısı (`--exit-code 1 --severity CRITICAL`).
- **Milestone 4:** Harbor'a imaj push ve post-action bildirimleri.

#### Final Acceptance Criteria
- Jenkins Console Log'unda tüm adımların yeşil (SUCCESS) olması ve Harbor üzerinde taranmış imajın listelenmesi.

---

### PROJECT-03 — Modern GitLab CI/CD GitOps Trigger Pipeline

#### Metadata
- **Classification:** **INSTRUCTOR SHOWCASE** (Eğitmen ekranında canlı gösterim)
- **Recommended Day:** Day 3
- **Level:** PRACTITIONER
- **Estimated Time:** 90 dk
- **Required Profiles:** `gitlab-ci`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-03`

#### Scenario
Modern bir SaaS şirketi tüm geliştirme ve CI süreçlerini GitLab CE 19.2 üzerinde yürütmektedir. Geliştiriciler kod push ettiğinde `.gitlab-ci.yml` devreye girerek test, dependency cache, SAST güvenlik taraması ve Docker imaj üretimini gerçekleştirecektir. Sınıfta bellek tüketimini dengeli tutmak adına bu proje eğitmen tarafından sunulur.

#### Learning Outcomes
- `.gitlab-ci.yml` pipeline mimarisi ve stages/jobs yapısı
- GitLab Runner Docker executor konfigürasyonu
- `cache` ve `artifacts` ayrımı ile pipeline hızlandırma
- Multi-architecture matrix buildleri

#### Architecture
```text
  [ GitLab Push ] ---> [ Runner ] ---> Test Job (Cache node_modules)
                                              |
                                              +---> Trivy FS Scan
                                              |
                                              +---> Docker Build & Push
```

#### Final Acceptance Criteria
- GitLab CI pipeline'ı yeşil tamamlanmalı, artifact olarak test raporu indirilebilmeli ve Harbor/GitLab Registry'de imaj oluşmalıdır.

---

### PROJECT-04 — Terraform Local Infrastructure as Code (IaC)

#### Metadata
- **Classification:** **OPTIONAL-TAKE-HOME** (Opsiyonel ev çalışması / ödev)
- **Recommended Day:** Day 4
- **Level:** PRACTITIONER
- **Estimated Time:** 60 dk
- **Required Profiles:** `docker` / `kubernetes`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-04`

#### Scenario
Bulut ortamına çıkmadan önce yerel altyapının (Docker ağları, kind Kubernetes cluster nesneleri ve Helm paketleri) Terraform 1.9+ ile deklaratif olarak kodlanması ve state yönetimi yapılması.

#### Learning Outcomes
- Terraform HCL2 dili, modül yapısı ve yerel providerlar (`kreuzwerker/docker`)
- `terraform.tfstate` yönetimi ve drift tespiti
- `terraform import` ile var olan kaynakları koda geçirme

#### Final Acceptance Criteria
- `terraform apply` ile kind üzerinde namespace, deployment ve service nesnelerinin başarıyla ayağa kalkması ve `terraform plan` çıktısında drift olmaması.

---

### PROJECT-04B — AWS Multi-AZ VPC Architecture with Terraform (Bryant Son Reference)

#### Metadata
- **Classification:** **PORTFOLIO CLOUD PROJECT** (Bulut Ağ Mimarisi Portfolyo Projesi)
- **Recommended Day:** Day 4
- **Level:** PRACTITIONER
- **Estimated Time:** 75 dk
- **Required Profiles:** `docker` (LocalStack) veya AWS CLI
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-TF-VPC`
- **Tam Uygulama Dokümanı:** [`outputs/labs/terraform/LAB-TF-08-terraform-aws-vpc-architecture.md`](../labs/terraform/LAB-TF-08-terraform-aws-vpc-architecture.md)

#### Scenario
Şirketin monolitik uygulamalarını ve mikroservislerini güvenli bir bulut ortamına taşımak üzere; AWS üzerinde Multi-AZ (us-east-1a, us-east-1b) yüksek erişilebilirlikli, DMZ katmanı (Public Subnetler), izole iş yükü katmanı (Private Subnetler), Internet Gateway, Elastic IP destekli NAT Gateway, Route Tables, Bastion Jump Host ve katmanlı Security Groups yapısı Terraform 1.10+ ile deklaratif kod olarak geliştirilir.

#### Learning Outcomes
- AWS VPC (`10.0.0.0/16`) ve Multi-AZ Subnet CIDR planlaması
- Internet Gateway ve Elastic IP ile bağlanan NAT Gateway mimarisi
- Ayrık Yönlendirme Tabloları (Public RT -> IGW, Private RT -> NAT Gateway)
- Bastion Host üzerinden ProxyJump (`ssh -J`) ile private EC2 erişimi
- Private sunucudan dış internete çıkışta NAT Gateway IP maskelemesinin (`curl https://checkip.amazonaws.com`) kanıtlanması

#### Architecture
```text
  [ Public Internet (0.0.0.0/0) ]
                 |
        [ Internet Gateway ]
                 |
     +-----------+-----------+ (Multi-AZ VPC: 10.0.0.0/16)
     |                       |
[ Public Subnet A ]    [ Public Subnet B ]
- Bastion (Port 22)    - Standby Ingress
- NAT Gateway (EIP)
     |                       |
[ Private Subnet A ]   [ Private Subnet B ]
- Private App Server   - Standby Database
(Egress -> NAT GW)     (Egress -> NAT GW)
```

#### Final Acceptance Criteria
- `terraform apply` ile 17 kaynağın hatasız oluşturulması.
- Bastion üzerinden Private EC2 sunucusuna SSH tüneliyle bağlanılabilmesi.
- Private sunucu içinden yapılan `curl https://checkip.amazonaws.com` sorgusunun NAT Gateway Elastic IP'sini döndürmesi.
- `scripts/validate.sh` testinin %100 PASS üretmesi.

---

### PROJECT-05 — Production-Ready Kubernetes Microservice Deployment

#### Metadata
- **Classification:** **MANDATORY IN-CLASS** (Gün 4 sınıf içi zorunlu ana proje)
- **Recommended Day:** Day 4
- **Level:** PRACTITIONER
- **Estimated Time:** 90 dk
- **Required Profiles:** `kubernetes`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-05`

#### Scenario
Kubernetes v1.31 ortamında çalışan bir sipariş servisinin üretim standartlarına kavuşturulması: CPU/Memory limitleri, Liveness/Readiness probları, Zero-Downtime Rolling Update, PodDisruptionBudget (PDB) ve ConfigMap/Secret ayrımı.

#### Learning Outcomes
- Resource QoS sınıfları ve OOMKilled engelleme
- Sağlık kontrolleri ile kesintisiz trafik yönlendirme
- RollingUpdate parametreleri (`maxSurge: 1`, `maxUnavailable: 0`)
- Dinamik PVC depolama bağlantısı

#### Final Acceptance Criteria
- Yük altında versiyon yükseltildiğinde hiçbir HTTP isteğinin düşmemesi (`0% error rate`) ve podların Burstable QoS ile çalışması.

---

### PROJECT-06 — Declarative GitOps Continuous Delivery with Argo CD

#### Metadata
- **Classification:** **EMBEDDED** (Gün 4 GitOps akışına gömülü)
- **Recommended Day:** Day 4
- **Level:** PRACTITIONER
- **Estimated Time:** 75 dk
- **Required Profiles:** `kubernetes`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-06`

#### Scenario
Kubernetes cluster'ındaki tüm uygulamaların manuel `kubectl` yerine Argo CD v3.4.2 ile GitOps üzerinden yönetilmesi; Git deposundaki manifest değiştiğinde otomatik sync ve self-healing yeteneklerinin doğrulanması.

#### Learning Outcomes
- Argo CD Application CRD tanımı
- Automated sync, prune ve self-heal mekanizmaları
- Git revert ile saniyeler içinde kararlı sürüme geri dönme (Rollback)

#### Final Acceptance Criteria
- Git'teki her commit cluster'a 1 dakika içinde yansımalı ve cluster'a yapılan manuel müdahaleler Argo CD tarafından otomatik düzeltilmelidir.

---

### PROJECT-07 — Full-Stack Observability with Prometheus & Grafana

#### Metadata
- **Classification:** **MANDATORY IN-CLASS** (Gün 5 sabah zorunlu proje)
- **Recommended Day:** Day 5
- **Level:** PRACTITIONER
- **Estimated Time:** 90 dk
- **Required Profiles:** `monitoring`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-07`

#### Scenario
Üretim kümesindeki tüm mikroservislerin ve altyapının (Node Exporter) metriklerinin Prometheus 3.13 LTS ile toplanması, Golden Signals (Latency, Traffic, Errors, Saturation) panellerinin Grafana 13.x'te çizilmesi ve Alertmanager v0.33 ile kritik alarmların kurulması.

#### Learning Outcomes
- PromQL sorgu dili (`rate`, `histogram_quantile`, `sum by`)
- Grafana dashboard ve data source provision etme
- Alertmanager ile alarm gruplama ve susturma

#### Final Acceptance Criteria
- Grafana üzerinde p95 gecikme ve RPS grafiklerinin canlı akması; simüle edilen kesintide `ServiceDown` alarmının Alertmanager'a düşmesi.

---

### PROJECT-08 — Centralized Log Analytics with Elasticsearch & Kibana

#### Metadata
- **Classification:** **FAST-CLASS** (Hızlı ilerleyen öğrenciler için opsiyonel)
- **Recommended Day:** Day 5
- **Level:** PRACTITIONER
- **Estimated Time:** 90 dk
- **Required Profiles:** `logging`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-08`

#### Scenario
Mikroservislerden basılan tüm yapılandırılmış JSON logların Vector toplayıcısı (0.40.2) tarafından okunup Elasticsearch 7.17.23'e indekslenmesi ve Kibana üzerinde hata arama panelleri oluşturulması.

#### Learning Outcomes
- Structured JSON logging standartları
- Vector log dönüştürme ve Elasticsearch bulk sink'i
- Kibana Data Views ve KQL (Kibana Query Language) ile arama

#### Final Acceptance Criteria
- Kibana veya REST API üzerinden `level: "ERROR"` sorgusu yapıldığında ilgili hatanın `trace_id` ve stack trace'i ile listelenmesi.

---

### PROJECT-09 — Production War Room: Multi-Failure Incident Recovery

#### Metadata
- **Classification:** **FAST-CLASS** (İleri seviye kriz simülasyonu)
- **Recommended Day:** Day 5
- **Level:** CHALLENGE
- **Estimated Time:** 60 dk
- **Required Profiles:** `kubernetes`
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-09`

#### Scenario
Eğitmen tarafından cluster'a aynı anda 4 kritik arıza enjekte edilir: CrashLoopBackOff, ImagePullBackOff, Yanlış NetworkPolicy engeli ve OOMKilled bellek sınırı. Öğrenci süreli bir kriz ortamında problemleri teşhis edip çözer ve postmortem raporu sunar.

#### Learning Outcomes
- `kubectl describe`, `logs --previous`, `get events` ile hızlı teşhis
- Kriz anında sakin ve sistematik problem çözme
- Kurumsal Blameless Postmortem kültürü ve 5-Whys kök neden analizi

#### Final Acceptance Criteria
- 4 arızalı servis 30 dakika içinde 1/1 Running durumuna getirilmeli ve eksiksiz postmortem markdown dosyası teslim edilmelidir.

---

### PROJECT-10 — Final Integrated Local Capstone: Code to Observability

#### Metadata
- **Classification:** **MANDATORY IN-CLASS** (Final büyük Capstone)
- **Recommended Day:** Day 5
- **Level:** CAPSTONE
- **Estimated Time:** 120 dk
- **Required Profiles:** `phased` (Aşamalı geçiş)
- **Target Repo Path:** `~/devops-workspace/projects/PROJECT-10`

#### Scenario
5 günlük eğitimin zirve noktası: Geliştirici Git'e yeni sürüm kodunu (`v2.0.0`) push eder. CI pipeline'ı test ve kalite kapılarını geçer, güvenli Docker imajını Harbor'a basar. GitOps manifestosu güncellenir, Argo CD v3.4 değişikliği kind cluster'ına sıfır kesintiyle uygular. Prometheus 3.x ve Grafana 13.x anlık RPS ve yanıt sürelerini ölçer, Vector tüm JSON logları Elasticsearch'e iletir.

#### Learning Outcomes
- Tüm 5 günün araçlarının tam entegrasyonu
- Gerçek dünya DevOps mühendisliği deneyimi
- Üretim seviyesinde otomasyon, güvenlik ve gözlemlenebilirlik

#### Final Acceptance Criteria
- `scripts/ci_pipeline_runner.sh` scripti çalıştırıldığında tüm 5 aşama (Test -> Sonar -> Trivy -> GitOps/Argo -> Observability) hatasız tamamlanmalı ve HTTP 200 OK yanıtı alınmalıdır.
