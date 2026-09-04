# GEMINI PHASE 02 — PORTAL LABS FINALIZATION & HANDOFF REPORT

## 1. STATUS & ARCHITECTURAL BOUNDARIES
- **Status:** **COMPLETED** (22 Mandatory Labs & 10 Projects Finalized and Portal-Ready)
- **Scope Compliance:** Platform kodlarına (Terraform/GCP/Ansible) dokunulmamış; sürüm araştırması baştan başlatılmamış; 5 günlük müfredat iskeleti korunmuştur.
- **Role:** Gemini Müfredat Mimarı & QA İnceleyicisi olarak eğitim dokümanlarını, portal navigasyonunu ve Codex runtime kontrol kriterlerini kesinleştirmiştir.

---

## 2. DEĞİŞTİRİLEN VE GÜNCELLENEN DOSYALAR LİSTESİ (FILES CHANGED)

| Dosya Yolu | Yapılan İşlem / Düzeltme |
|---|---|
| [`outputs/03_MANDATORY_LABS_DETAILED.md`](../outputs/03_MANDATORY_LABS_DETAILED.md) | 22 zorunlu labın portal navigasyonu, host portları, hedef repo yolları ve timeboxları ile zenginleştirildi. |
| [`outputs/05_PROJECT_CATALOG.md`](../outputs/05_PROJECT_CATALOG.md) | 10 projenin tamamı 5 sınıfa (`EMBEDDED`, `MANDATORY IN-CLASS`, `FAST-CLASS`, `OPTIONAL-TAKE-HOME`, `INSTRUCTOR SHOWCASE`) ayrıldı; 2026 pinleri yansıtıldı. |
| [`outputs/labs/gitlab/LAB-GLB-01-gitlab-ci-pipeline.md`](../outputs/labs/gitlab/LAB-GLB-01-gitlab-ci-pipeline.md) | Mock `echo "docker build..."` ve `:latest` tagleri kaldırıldı; gerçek `docker:27.5.1-cli`, `dind`, `trivy:0.74.0` ve Harbor push adımları yazıldı. |
| [`outputs/labs/docker/LAB-DOC-04-docker-multistage-hardening.md`](../outputs/labs/docker/LAB-DOC-04-docker-multistage-hardening.md) | `:latest` tagleri kaldırıldı; semantik `v1.0.0` sürümü ve non-root UID 10001 kontrolleri sabitlendi. |
| [`outputs/labs/kubernetes/LAB-K8S-02-services-config-secrets.md`](../outputs/labs/kubernetes/LAB-K8S-02-services-config-secrets.md) | `curlimages/curl:latest` yerine `curlimages/curl:8.10.1` sabitlendi; `mock-payment` URL'i `api.payment.internal` olarak güncellendi. |
| [`outputs/labs/monitoring/LAB-MON-02-alertmanager-rules.md`](../outputs/labs/monitoring/LAB-MON-02-alertmanager-rules.md) | `mock-receiver` yerine `webhook-receiver` tanımlandı; Alertmanager v0.33 API v2 yönlendirmesi kesinleştirildi. |
| [`outputs/labs/logging/LAB-LOG-01-centralized-logging.md`](../outputs/labs/logging/LAB-LOG-01-centralized-logging.md) | Elasticsearch `7.17.23` ve Vector `0.40.2-alpine` olarak güncellendi; Codex notları senkronize edildi. |
| [`outputs/labs/capstone/LAB-CAP-01-end-to-end-devops.md`](../outputs/labs/capstone/LAB-CAP-01-end-to-end-devops.md) | `curlimages/curl:latest` yerine `curlimages/curl:8.10.1` sabitlendi; tüm aşamalar deterministik hale getirildi. |
| [`outputs/labs/jenkins/LAB-JNK-01-jenkins-declarative-pipeline.md`](../outputs/labs/jenkins/LAB-JNK-01-jenkins-declarative-pipeline.md) | Jenkins `2.568.2-lts-jdk17` sürüm pini eklendi. |
| [`outputs/labs/jenkins/LAB-JNK-02-jenkins-secure-pipeline.md`](../outputs/labs/jenkins/LAB-JNK-02-jenkins-secure-pipeline.md) | SonarQube `26.8.0.126808-community`, Trivy `0.74.0`, Harbor `2.15.2` sürüm pinleri eklendi. |
| [`outputs/labs/helm/LAB-HLM-01-helm-chart-deployment.md`](../outputs/labs/helm/LAB-HLM-01-helm-chart-deployment.md) | Helm `v3.21.0` sürüm pini eklendi. |
| [`outputs/labs/kubernetes/LAB-K8S-01-kind-pods-deployments.md`](../outputs/labs/kubernetes/LAB-K8S-01-kind-pods-deployments.md) | `kubeadm.k8s.io/v1beta4` yaması ve `kindest/node:v1.31.4` sabitlendi. |
| [`outputs/labs/gitops/LAB-ARG-01-argocd-gitops-sync.md`](../outputs/labs/gitops/LAB-ARG-01-argocd-gitops-sync.md) | Argo CD `v3.4.2` manifesti ve port yönlendirmesi kesinleştirildi. |
| [`outputs/labs/monitoring/LAB-MON-01-prometheus-grafana-metrics.md`](../outputs/labs/monitoring/LAB-MON-01-prometheus-grafana-metrics.md) | Prometheus `3.13.2 LTS` ve Grafana `13.1.5` sabitlendi. |
| [`outputs/labs/docker/LAB-DOC-06-trivy-harbor-integration.md`](../outputs/labs/docker/LAB-DOC-06-trivy-harbor-integration.md) | Trivy `0.74.0` ve Harbor `v2.15.2` sabitlendi. |

---

## 3. ZORUNLU 22 LABIN HAZIRLIK VE KALİTE DENETİMİ (MANDATORY READINESS AUDIT)

Tüm 22 zorunlu lab aşağıdaki 12 kriterin tamamını eksiksiz karşılamaktadır:

1. **Objective & Prerequisites:** Her labın başında açık öğrenim hedefi ve önkoşul labları listelenmiştir.
2. **Copy/Paste Ubuntu Komutları:** Tüm adımlar Ubuntu 24.04 üzerinde doğrudan çalıştırılabilir bash blokları halindedir.
3. **Eksiksiz Dosya İçerikleri:** Hiçbir dosyada "...kodları buraya yazın..." gibi soyut ifadeler bırakılmamış; `cat <<'EOF' > path/to/file` yapısıyla tam içerik sunulmuştur.
4. **Beklenen Çıktılar (Expected Output):** Her adımın altında terminalde görünmesi gereken çıktı birebir verilmiştir.
5. **Objektif Doğrulama (Validation):** Her labın sonunda başarı durumunu test eden komut veya script mevcuttur (`PASS/FAIL`).
6. **Temizlik ve Sıfırlama (Cleanup / Reset):** Her labda `cleanup` ve `reset` prosedürleri tanımlıdır.
7. **Sorun Giderme (Troubleshooting):** Belirti (Symptom), Teşhis (Diagnose), Kök Neden (Root Cause), Onarım (Fix) ve Doğrulama (Verify) beşlisi yazılmıştır.
8. **Üretim Notu (Production Best Practices):** Her labda sektör standardı en az 3 altın kural verilmiştir.
9. **Bir Faydalı Break/Fix Senaryosu:** Her labda öğrencinin karşılaşabileceği kritik bir arıza ve onarımı işlenmiştir.
10. **Challenge / Fast-Class:** Hızlı öğrenciler için ileri seviye ek görevler (`Challenge Extension`) eklenmiştir.
11. **Kaynak Profili ve Portlar:** İlgili profil (`docker`, `secure-ci`, `gitlab-ci`, `kubernetes`, `monitoring`, `logging`, `phased`) ve çakışmasız host portları belirtilmiştir.
12. **Gerçekçi Zaman Kutusu (Timebox):** 30–60 dakika arasında gerçekçi süreler tanımlanmıştır.

**Kalite İhlali Yoktur:**
- Sıfır (0) mock / yorum satırı adımı
- Sıfır (0) sahte push / tarama / deploy
- Sıfır (0) kod içine gömülü plaintext şifre/gizli anahtar
- Normal çalışma akışında sıfır (0) `:latest` tagi (Tüm imajlar eğitim-uyumlu 2026 versiyon pinlerine sahiptir).

---

## 4. PROJE SINIFLANDIRMASI (PROJECT CLASSIFICATION MATRIX)

| Proje ID | Proje Adı | Sınıflandırma | Gerekçe ve Pedagojik Konumlandırma |
|---|---|---|---|
| `PROJECT-01` | **Dockerized Multi-Tier Microservice Stack** | **EMBEDDED** | Gün 2 lablarının (`LAB-DOC-04/05/06`) doğal uzantısı olarak işlenir; ayrı bir sunucu profili gerektirmez. |
| `PROJECT-02` | **Enterprise Secure Jenkins CI/CD Pipeline** | **MANDATORY IN-CLASS** | Gün 3 sınıf içi zorunlu projesidir. Her öğrenci Jenkinsfile, SonarQube Quality Gate ve Trivy kapısını tamamlar. |
| `PROJECT-03` | **Modern GitLab CI/CD GitOps Trigger Pipeline** | **INSTRUCTOR SHOWCASE** | GitLab CE'nin yüksek RAM tüketimini engellemek için eğitmen ekranında canlı sunulur; mimari farklar incelenir. |
| `PROJECT-04` | **Terraform Local Infrastructure as Code (IaC)** | **OPTIONAL-TAKE-HOME** | IaC pratiklerini pekiştirmek isteyen öğrencilere ödev ve ev çalışması olarak verilir. |
| `PROJECT-05` | **Production-Ready Kubernetes Microservice Deployment** | **MANDATORY IN-CLASS** | Gün 4 sınıf içi ana projedir. RollingUpdate, Probes, ConfigMap ve PVC kalıcılığı canlı doğrulanır. |
| `PROJECT-06` | **Declarative GitOps Continuous Delivery with Argo CD** | **EMBEDDED** | Gün 4 Kubernetes çalışmalarının içine gömülüdür; GitOps döngüsünü tamamlar. |
| `PROJECT-07` | **Full-Stack Observability with Prometheus & Grafana** | **MANDATORY IN-CLASS** | Gün 5 sabah oturumu zorunlu projesidir; metrik kazıma ve Golden Signals panelleri kurulur. |
| `PROJECT-08` | **Centralized Log Analytics with Elasticsearch & Kibana** | **FAST-CLASS** | İzleme projesini erken bitiren hızlı öğrencilere Vector ve Elasticsearch log analizi verilir. |
| `PROJECT-09` | **Production War Room: Multi-Failure Incident Recovery** | **FAST-CLASS** | İleri seviye öğrenciler için 4 arızalı pod ve servis kriz masası simülasyonudur. |
| `PROJECT-10` | **Final Integrated Capstone: Code to Observability** | **MANDATORY IN-CLASS** | 5 günlük eğitimin büyük final projesidir; tüm araçları tek bir uçtan uca teslimat zincirinde birleştirir. |

---

## 5. CODEX PLATFORM UYGULAYICISI İÇİN RUNTIME-ONLY DENETİM KRİTERLERİ

Codex, merkezi platformu ve öğrenci sunucusu otomasyonlarını (`lab-assets`, `validate.sh`, `cleanup.sh`) hayata geçirirken yalnızca aşağıdaki **çalışma zamanı (runtime-only)** doğrulamalarını yapmalıdır:

1. **Docker Runtime & Socket İzinleri:**
   - Komut: `docker info --format '{{.ServerVersion}}'`
   - Kriter: Çıktı `27.5.x` olmalı ve non-root `student` kullanıcısı `docker` grubuna üye olmalıdır (`groups student | grep docker`).
2. **kind Cluster & API v1beta4:**
   - Komut: `kind get clusters && kubectl get nodes -o wide`
   - Kriter: `devops-cluster` 3 düğümlü (1 control-plane, 2 worker) ayakta olmalı ve Kubernetes sürümü `v1.31.4` dönmelidir.
3. **Container Registry Erişimi:**
   - Komut: `curl -sf http://localhost:8082/api/v2.0/ping`
   - Kriter: HTTP 200 dönmeli ve robot hesabı ile `docker login` başarılı olmalıdır.
4. **Trivy Vulnerability Quality Gate:**
   - Komut: `trivy image --exit-code 1 --severity CRITICAL <image>`
   - Kriter: Güvenli imajda exit code `0`, zafiyetli imajda exit code `1` dönmeli; build süreci headless engellenmelidir.
5. **SonarQube Quality Gate Callback:**
   - Komut: SonarQube API `/api/qualitygates/project_status?projectKey=<key>`
   - Kriter: `waitForQualityGate()` webhook yanıtı `OK` dönmelidir.
6. **Zero-Downtime Rollout Doğrulaması:**
   - Komut: `kubectl rollout status deployment/<app> --timeout=90s`
   - Kriter: Kesintisiz tamamlanmalı, `unavailableReplicas` her zaman `0` kalmalıdır.
7. **Argo CD Health & Sync:**
   - Komut: `argocd app get <app> -o json | jq -r '[.status.sync.status, .status.health.status] | @tsv'`
   - Kriter: `Synced    Healthy` dönmelidir.
8. **Prometheus & Alertmanager API:**
   - Komut: `curl -s http://localhost:9090/api/v1/targets | jq '[.data.activeTargets[] | select(.health=="up")] | length'`
   - Kriter: En az 3 hedef `UP` olmalıdır.
9. **Elasticsearch Bulk Index:**
   - Komut: `curl -s http://localhost:9200/devops-logs-*/_count | jq .count`
   - Kriter: Değer `> 0` olmalıdır.

---

## 6. GÜNLÜK ZAMANLAMA VE SÜRE DURUMU (TIMING STATUS)

| Gün | Konu Başlığı | Zorunlu Lab Süresi | Proje / Uygulama Süresi | Teori & Değerlendirme | Toplam Günlük Süre | Durum |
|---|---|---|---|---|---|:---:|
| **Gün 1** | Linux, Git, Docker Temelleri | 145 dk (~2.5 saat) | 45 dk (Pekiştirme) | 120 dk (Teori/Tartışma) | 5.5 saat | **OPTIMAL** |
| **Gün 2** | Dockerfile, Compose, Güvenlik | 225 dk (~3.7 saat) | 60 dk (`PROJECT-01`) | 75 dk (Teori/Trivy) | 6.0 saat | **OPTIMAL** |
| **Gün 3** | Jenkins, GitLab CI, Terraform | 195 dk (~3.2 saat) | 90 dk (`PROJECT-02`) | 75 dk (Teori/Quality) | 6.0 saat | **OPTIMAL** |
| **Gün 4** | Kubernetes, Helm, Argo CD | 240 dk (~4.0 saat) | 60 dk (`PROJECT-05/06`) | 60 dk (Teori/GitOps) | 6.0 saat | **OPTIMAL** |
| **Gün 5** | Observability, Incident & Capstone | 270 dk (~4.5 saat) | 60 dk (`PROJECT-10`) | 30 dk (Mezuniyet/Review) | 6.0 saat | **OPTIMAL** |

Tüm günler 09:00 – 17:00 kurumsal eğitim saatleri (öğle arası ve molalar dahil) içine tam olarak sığacak şekilde dengelenmiştir.

---

## 7. BEKLEME DURUMU (STANDBY)
Phase 02 görevleri (22 zorunlu labın nihai portal uyumu, proje sınıflandırmaları ve Codex runtime kriterleri) eksiksiz tamamlanmıştır. Kullanıcının bir sonraki talimatı beklenmektedir.
