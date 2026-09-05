# 09 — BÜYÜK FİNAL CAPSTONE MİMARİ PLANI (FINAL LOCAL CAPSTONE BLUEPRINT)

## 1. Genel Bakış ve Senaryo

Bu doküman, 5 günlük **DevOps Practitioner** eğitiminin tüm kazanımlarını birleştiren büyük final projesinin (**PROJECT-10 / LAB-CAP-01**) uçtan uca mimarisini, aşamalı profil yürütme planını ve teknik doğrulama standartlarını açıklar.

### Büyük Resim: Tek Bir Zincirde DevOps Yaşam Döngüsü
```text
  +---------------------------------------------------------------------------------------------------+
  |                                 THE COMPLETE DEVOPS DELIVERY CHAIN                                |
  |                                                                                                   |
  |  [ Developer ] ---> Git Commit / Push (v1.2.0)                                                    |
  |                           |                                                                       |
  |                           v                                                                       |
  |  [ CI Pipeline (Jenkins / GitLab CI) ]                                                            |
  |    ├── 1. Unit Tests (pytest / JUnit XML) -------------------------> [ PASS ]                     |
  |    ├── 2. SonarQube Static Code Analysis -------------------------> [ QUALITY GATE OK ]           |
  |    ├── 3. Multi-Stage Hardened Docker Build (Non-root UID 10001) ---> [ SUCCESS ]                |
  |    ├── 4. Trivy Container Vulnerability Scan ----------------------> [ 0 CRITICAL CVE ]           |
  |    └── 5. Push to Harbor Private Registry (registry.local/apps:1.2.0)                             |
  |                           |                                                                       |
  |                           v                                                                       |
  |  [ GitOps Repo Update (Manifests / Helm) ] (Image Tag: 1.2.0)                                     |
  |                           |                                                                       |
  |                           v (Argo CD Automated Sync / Reconcile)                                  |
  |  [ kind Kubernetes Multi-Node Cluster ]                                                           |
  |    ├── Zero-Downtime Rolling Update (maxSurge: 1, maxUnavailable: 0)                             |
  |    ├── Probes Verified (Readiness/Liveness)                                                       |
  |    └── ClusterIP Service & Ingress Routing                                                        |
  |                           |                                                                       |
  |                           v                                                                       |
  |  [ Observability & Operational Feedback ]                                                         |
  |    ├── Prometheus scrapes /metrics (RPS, Latency, Errors)                                         |
  |    ├── Grafana displays Golden Signals Live Dashboard                                             |
  |    ├── Vector streams structured JSON logs to Elasticsearch                                       |
  |    └── Kibana provides full trace search & error visualization                                    |
  +---------------------------------------------------------------------------------------------------+
```

---

## 2. Tek Sunucuda Aşamalı Yürütme Modeli (Phased Profiles)

Öğrencinin tek bir Ubuntu sunucusunda (8–16 GB RAM) bellek tıkanması yaşamaması için Capstone projesi **3 aşamalı profil geçişi (Phased Profiles)** ile yürütülür:

```text
  [ PHASE 1: CI & SECURITY ] ───► [ PHASE 2: K8S & GITOPS ] ───► [ PHASE 3: OBSERVABILITY ]
   - Profile: secure-ci           - Profile: kubernetes           - Profile: monitoring & logging
   - RAM Budget: ~4.0 GB          - RAM Budget: ~3.5 GB           - RAM Budget: ~4.0 GB
   - Build, Sonar, Trivy, Harbor  - kind Cluster, Argo CD, App    - Prometheus, Grafana, Vector, ES
```

### Aşama 1: CI & Güvenlik Kapısı (Phase 1: CI & Security Gate)
* **Aktif Profil:** `profile: secure-ci` (Jenkins + SonarQube + Harbor veya Docker)
* **İşlemler:**
  1. Geliştirici kodu yazar ve birim testleri koşturur.
  2. SonarQube Quality Gate analizi yapılır.
  3. Multi-stage Docker imajı üretilir ve Trivy ile taranır.
  4. Onaylı imaj etiketlenip Harbor Registry'ye aktarılır.
* **Geçiş Kuralı:** İmaj başarıyla üretilip taranınca CI konteynerleri durdurulabilir veya arka plana alınabilir.

### Aşama 2: Kubernetes & GitOps Dağıtımı (Phase 2: Delivery & GitOps)
* **Aktif Profil:** `profile: kubernetes` (kind Multi-Node Cluster + Argo CD)
* **İşlemler:**
  1. GitOps deposundaki `deployment.yaml` imaj tagi `1.2.0` olarak güncellenir.
  2. Argo CD değişikliği otomatik algılar (`Automated Sync`).
  3. kind cluster üzerinde sıfır kesintili `RollingUpdate` gerçekleşir.
  4. Liveness ve Readiness probları yeşile döner.

### Aşama 3: Gözlemlenebilirlik ve Doğrulama (Phase 3: Observability & Feedback)
* **Aktif Profil:** `profile: monitoring` + `profile: logging` (Prometheus + Grafana + Vector + Elasticsearch)
* **İşlemler:**
  1. Uygulamaya sentetik HTTP trafiği basılır (`curl` / `hey`).
  2. Prometheus `/metrics` endpointinden RPS ve 95. yüzdelik gecikmeyi toplar.
  3. Grafana Golden Signals paneli açılır.
  4. Vector konteyner loglarını okuyup Elasticsearch'e basar, Kibana'da JSON logları listelenir.

---

## 3. Kilometre Taşları ve Doğrulama Kriterleri

| Milestone | Aşama | Başarı Kriteri (Acceptance Criteria) | Doğrulama Komutu |
|---|---|---|---|
| **M1: Code & Test** | CI | Pytest 5/5 passed, JUnit XML raporu üretildi | `pytest --junitxml=reports/junit.xml tests/` |
| **M2: Quality & Sec** | CI | SonarQube QG = PASSED, Trivy CRITICAL = 0 | `trivy image --exit-code 1 --severity CRITICAL ...` |
| **M3: Registry Push** | CI | Harbor üzerinde imzalı imaj etiketi mevcut | `docker inspect <harbor_image>` |
| **M4: GitOps Sync** | CD | Argo CD App durumu `Synced & Healthy` | `argocd app get capstone-order-api` |
| **M5: Zero-Downtime** | K8s | 2/2 replika Running, Rollout tamamlandı | `kubectl rollout status deployment/capstone-order-api` |
| **M6: Metrics Scrape**| Obs | Prometheus Target `UP`, PromQL rate > 0 | `curl -s http://localhost:9090/api/v1/targets` |
| **M7: Log Stream** | Obs | Elasticsearch indeksinde JSON log belgeleri var | `curl -s http://localhost:9200/devops-logs-*/_count` |

---

## 4. Final Doğrulama ve Capstone Sertifikasyon Scripti

Tüm adımları tek seferde doğrulayan uçtan uca test scripti:
```bash
~/devops-workspace/labs/LAB-CAP-01/scripts/ci_pipeline_runner.sh
```

Beklenen Nihai Konsol Çıktısı:
```text
==========================================================
  [STAGE 1] CI: Running Unit Tests & Quality Preflights   
==========================================================
Unit tests PASSED (1/1).
==========================================================
  [STAGE 2] CI: Multi-Stage Container Build               
==========================================================
Image built successfully: localhost:5000/devops/order-api:1.2.0
==========================================================
  [STAGE 3] SEC: Trivy Vulnerability Quality Gate         
==========================================================
Trivy Scan: 0 CRITICAL CVE found. Quality Gate PASSED.
==========================================================
  [STAGE 4] CD/GitOps: Loading Image & Syncing K8s       
==========================================================
deployment.apps/capstone-order-api successfully rolled out.
==========================================================
  [STAGE 5] Observability Verification                    
==========================================================
HTTP 200 OK - Capstone Order Service v1.2.0 is Live!
==========================================================
  CAPSTONE PIPELINE SUCCESS: FULL DEVOPS CHAIN VERIFIED!  
==========================================================
```
