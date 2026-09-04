# 14 — EĞİTMEN DERS ANLATIM VE YÖNETİM REHBERİ (INSTRUCTOR DELIVERY MASTER GUIDE)

Bu doküman, 5 günlük **DevOps Practitioner** eğitimini verecek Senior DevOps Eğitmeni için gün bazında ders akışını, 6 adımlı pedagojik döngüyü (`LEARN -> SEE -> BUILD -> VERIFY -> BREAK/FIX -> CHALLENGE`), merkezi platform referans gösterimlerini (SEE IT), yavaş/normal/hızlı sınıf stratejilerini, profil geçişlerini ve reset prosedürlerini içerir.

---

## 1. Altı Adımlı Pedagojik Ders Döngüsü (The 6-Step DevOps Loop)

Eğitmen, her konu ve lab bloğunda aşağıdaki 6 aşamayı sırasıyla işletir:

```text
  [ 1. LEARN ] -----> Teorik Kavram, Sektör İhtiyacı, "Neden?" Sorusu (15-20 dk)
         |
  [ 2. SEE IT ] ----> Merkezi Kurumsal Platformda Canlı İnceleme (devopsatolyesi.com) (10 dk)
         |
  [ 3. BUILD ] -----> Öğrencinin Kendi Sunucusunda Adım Adım İnşa Etmesi (Hands-on) (30-45 dk)
         |
  [ 4. VERIFY ] ----> Otomasyon / Validation Scripti ile Objektif PASS/FAIL Denetimi (5 dk)
         |
  [ 5. BREAK/FIX ] -> Kasıtlı Arıza Enjeksiyonu ve Sistematik Sorun Giderme (15-20 dk)
         |
  [ 6. CHALLENGE ] -> Hızlı Öğrenciler İçin İleri Düzey Ek Görev / Fast-Class (Opsiyonel)
```

---

## 2. Günlük Ders Akışı ve Sınıf Seviye Yönetimi

### GÜN 1: DevOps Kültürü, Linux Preflight, Git İş Akışları ve Docker Giriş
* **Zorunlu Lablar:** `LAB-LNX-01`, `LAB-GIT-01`, `LAB-DOC-01`, `LAB-DOC-02`
* **Aktif Profil:** `profile: docker` (RAM: ~1.5 GB)
* **Merkezi Gösterim (SEE IT):**
  - Eğitmen `https://devopsatolyesi.com` üzerinde çalışan bir mikroservisin DNS yapısını, port yönlendirmesini ve process izolasyonunu gösterir.
* **Öğrencinin İnşa Edeceği (BUILD):**
  - Kendi Ubuntu sunucusunda port ve bellek preflight scripti koşturma, Git merge conflict çözümü, Nginx ve PostgreSQL konteynerlerini başlatıp volume kalıcılığını test etme.
* **Yavaş Sınıf Yolu (Slow-Class Path):**
  - `LAB-GIT-01` merge conflict adımında `solution/app-config.json` dosyasını doğrudan kopyalatıp tek commit ile ilerleyin.
* **Normal Sınıf Yolu (Normal-Class Path):**
  - Tüm 4 zorunlu labı adım adım tamamlayın; her labın `Validation` scriptini çalıştırın.
* **Hızlı Sınıf Yolu (Fast-Class Path):**
  - `LAB-LNX-04` (cgroups & OOM Killer simülasyonu) ve `LAB-GIT-02` (Interactive Rebase Squash) challenge görevlerini verin.
* **Gün Sonu Hedefi:** Öğrenci sunucusunda Docker ayağa kalkmış, volume kalıcılığı doğrulanmış ve temiz bir Git geçmişi kurulmuştur.

---

### GÜN 2: Docker Mühendisliği, Konteyner Güvenliği ve Çok Katmanlı Uygulamalar
* **Zorunlu Lablar:** `LAB-DOC-03`, `LAB-DOC-04`, `LAB-DOC-05`, `LAB-DOC-06` + `PROJECT-01` (EMBEDDED)
* **Aktif Profil:** `profile: docker` -> `profile: secure-ci` (Harbor)
* **Merkezi Gösterim (SEE IT):**
  - `https://devopsatolyesi.com/harbor` arayüzüne girilerek kurumsal imaj depoları, robot hesapları, CVE güvenlik tarama raporları ve imzalı OCI artifactleri incelenir.
* **Öğrencinin İnşa Edeceği (BUILD):**
  - Multi-stage ve non-root (`UID 10001`) Dockerfile yazımı, `compose.yaml` ile API + DB + Redis çok katmanlı mikroservis orkestrasyonu, Trivy v0.74 ile CVE taraması ve Harbor'a push.
* **Yavaş Sınıf Yolu (Slow-Class):**
  - `LAB-DOC-06` Harbor push adımını eğitmen ekranında gösterip öğrenciye yerel imaj tagi ile Trivy taraması yaptırın.
* **Normal Sınıf Yolu (Normal-Class):**
  - 4 zorunlu labı ve `PROJECT-01` pekiştirmesini tamamlayın.
* **Hızlı Sınıf Yolu (Fast-Class):**
  - `LAB-DOC-07` (Google Distroless imajı üretimi) ve `LAB-DOC-08` (Syft ile SBOM çıkarma) görevlerini açın.
* **Gün Sonu Hedefi:** 1.2 GB imaj yerine 160 MB'lık sıkılaştırılmış, sıfır CRITICAL CVE barındıran ve healthcheck ile bağlanan servis mimarisi hazır olmalıdır.

---

### GÜN 3: CI/CD Otomasyonu, Kalite & Güvenlik Kapıları, Terraform Giriş
* **Zorunlu Lablar:** `LAB-JNK-01`, `LAB-JNK-02`, `LAB-GLB-01`, `LAB-TF-01` + `PROJECT-02` (MANDATORY IN-CLASS)
* **Eğitmen Canlı Gösterimi:** `PROJECT-03` (INSTRUCTOR SHOWCASE - GitLab CE & Runner)
* **Opsiyonel Ev Çalışması:** `PROJECT-04` (OPTIONAL-TAKE-HOME - Terraform IaC)
* **Aktif Profil:** `profile: secure-ci` (Jenkins 2.568 + SonarQube 26.8 + Harbor 2.15)
* **Merkezi Gösterim (SEE IT):**
  - `https://devopsatolyesi.com/jenkins` ve `https://devopsatolyesi.com/sonarqube` üzerinde kurumsal Quality Gate kuralları ve webhook akışları gösterilir.
* **Öğrencinin İnşa Edeceği (BUILD):**
  - `Jenkinsfile` Declarative Pipeline kodlaması, SonarQube statik kod analizi, `waitForQualityGate()` webhook onayı, Trivy blocker ve Harbor credentials binding.
* **Yavaş Sınıf Yolu (Slow-Class):**
  - Jenkins Console çıktısını adım adım izletin; GitLab CI adımlarını syntax linting seviyesinde tutun.
* **Normal Sınıf Yolu (Normal-Class):**
  - `LAB-JNK-01`, `LAB-JNK-02`, `LAB-TF-01` ve `PROJECT-02`'yi tam olarak tamamlayın.
* **Hızlı Sınıf Yolu (Fast-Class):**
  - `LAB-JNK-07` (Shared Libraries) ve `LAB-GLB-05` (DAG Needs Pipeline) meydan okumalarını başlatın.
* **Gün Sonu Hedefi:** Kod push edildiğinde otomatik test, SonarQube ve Trivy kapılarından geçen çalışan bir CI boru hattı kurulmuştur.

---

### GÜN 4: Kubernetes Orkestrasyonu, Helm Paketleme ve Argo CD ile GitOps
* **Zorunlu Lablar:** `LAB-K8S-01`, `LAB-K8S-02`, `LAB-K8S-03`, `LAB-HLM-01`, `LAB-ARG-01` + `PROJECT-05` (MANDATORY IN-CLASS) + `PROJECT-06` (EMBEDDED)
* **Aktif Profil:** `profile: kubernetes` (kind 3-Node Cluster + Argo CD v3.4)
* **Merkezi Gösterim (SEE IT):**
  - `https://devopsatolyesi.com/argocd` ve `https://devopsatolyesi.com/headlamp` üzerinde onlarca mikroservisin canlı topolojisi, drift tespiti ve pod dağılımı incelenir.
* **Öğrencinin İnşa Edeceği (BUILD):**
  - 3 düğümlü kind kümesi (K8s v1.31.4, kubeadm v1beta4), Probes, Limits, RollingUpdate, Helm Chart şablonlama ve Argo CD ile deklaratif GitOps senkronizasyonu.
* **Yavaş Sınıf Yolu (Slow-Class):**
  - Helm chart karmaşık şablonları yerine temel `values.yaml` geçersiz kılmalarına odaklanın.
* **Normal Sınıf Yolu (Normal-Class):**
  - Tüm 5 zorunlu labı ve `PROJECT-05/06`'yı eksiksiz yürütün.
* **Hızlı Sınıf Yolu (Fast-Class):**
  - `LAB-K8S-10` (HPA ile otomatik ölçekleme) ve `LAB-K8S-12` (Zero Trust NetworkPolicies) görevlerini verin.
* **Gün Sonu Hedefi:** kind kümesinde sıfır kesintili çalışan, sağlık probları ve kalıcı depolaması olan, Argo CD ile Git deposuna bağlı self-healing mikroservis mimarisi.

---

### GÜN 5: Gözlemlenebilirlik (Observability), Olay Yönetimi (War Room) ve Final Capstone
* **Zorunlu Lablar:** `LAB-MON-01`, `LAB-MON-02`, `LAB-LOG-01`, `LAB-INC-01`, `LAB-CAP-01` + `PROJECT-07` (MANDATORY IN-CLASS) + `PROJECT-10` (MANDATORY IN-CLASS)
* **Hızlı Sınıf Projeleri:** `PROJECT-08` (FAST-CLASS - Logging), `PROJECT-09` (FAST-CLASS - War Room)
* **Aktif Profil:** `profile: monitoring` -> `profile: logging` -> `profile: phased` (Capstone)
* **Merkezi Gösterim (SEE IT):**
  - `https://devopsatolyesi.com/grafana` ve `https://devopsatolyesi.com/kibana` üzerinde canlı üretim Golden Signals metrikleri, alert bildirimleri ve dağıtık izleme gösterilir.
* **Öğrencinin İnşa Edeceği (BUILD):**
  - Prometheus 3.13 LTS ve Grafana 13 panelleri, Alertmanager v0.33 kuralları, Vector ile JSON log toplama, War Room kriz masasında 3 kritik arızanın teşhisi ve nihai uçtan uca Capstone boru hattı (`scripts/ci_pipeline_runner.sh`).
* **Yavaş Sınıf Yolu (Slow-Class):**
  - Capstone adımında `scripts/ci_pipeline_runner.sh` scriptini eğitmen rehberliğinde çalıştırıp her aşamanın çıktısını birlikte yorumlayın.
* **Normal Sınıf Yolu (Normal-Class):**
  - Tüm zorunlu labları ve `PROJECT-07`, `PROJECT-10` projelerini tamamlayın.
* **Hızlı Sınıf Yolu (Fast-Class):**
  - `PROJECT-08` (Elasticsearch analizi) ve `PROJECT-09` (4 arızalı War Room) projelerini çözdürün.
* **Gün Sonu Hedefi:** Geliştiricinin commit atmasından production Kubernetes dağıtımına ve Grafana/Elasticsearch gözlemlenebilirliğine kadar tam donanımlı mezuniyet.

---

## 3. Profil Değiştirme ve Bellek Yönetim Talimatı (Memory Budget Protocol)

Öğrenci sunucusunda OOM Killer tetiklenmesini önlemek için eğitmen gün geçişlerinde şu komutları uygulattırır:

```bash
# Gün 3 sonu: CI servislerini durdurup Gün 4 Kubernetes profiline geçiş
docker stop jenkins sonarqube harbor-core harbor-db harbor-portal 2>/dev/null || true

# Gün 4 sonu: kind kümesini silip Gün 5 Monitoring profiline geçiş
kind delete cluster --name devops-cluster 2>/dev/null || true

# Acil Durum Bellek Boşaltma (OOM Önleyici)
docker system prune -f --volumes
sudo sync && sudo sysctl -w vm.drop_caches=3
```

---

## 4. Acil Durum Sıfırlama ve Kurtarma Prosedürü (Emergency Reset)

Öğrenci bir labda çözülemeyecek bir yapılandırma hatasına düştüğünde:
1. `cd ~/devops-workspace/labs/LAB-XXX/scripts && ./reset.sh` çalıştırılır.
2. Eğer script yoksa `rm -rf ~/devops-workspace/labs/LAB-XXX` yapılır ve ilgili lab markdown dosyasındaki `Step 1` komutları sıfırdan yapıştırılır.
3. Docker için `docker rm -f $(docker ps -aq)` uygulanır.
4. Kubernetes için `kind delete cluster --name devops-cluster` ile temiz bir küme başlatılır.
