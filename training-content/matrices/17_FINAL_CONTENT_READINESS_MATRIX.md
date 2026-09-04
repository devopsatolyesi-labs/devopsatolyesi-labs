# 17 — NİHAİ EĞİTİM İÇERİĞİ VE LAB HAZIRLIK MATRİSİ (FINAL CONTENT READINESS MATRIX)

**Tarih:** 27 Ağustos 2026  
**Kapsam:** 22 Zorunlu Lab ve 10 Projenin Öğrenci Portalı & Codex Handoff Hazırlık Durumu  
**Kural:** İçerik eksiksizliği onaylanırken, fiziksel platformda çalışma zamanı testi henüz icra edilmediği için durum dürüstçe `CONTENT READY / RUNTIME PENDING CODEX` olarak belirtilmiştir.

---

## 1. 22 Zorunlu Lab İçerik ve Hazırlık Durumu Matrisi

| Lab ID | Teknoloji | Student-ready? | Commands complete? | Validation? | Cleanup? | Break/Fix? | Profile/Ports | Codex runtime validation needed | Durum (Readiness Status) | Notlar |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|---|:---:|---|
| `LAB-ENV-00` | Environment Setup | YES | YES | YES | YES | YES | `docker` / Tüm Portlar | `validate-environment.sh` -> 0 FAIL | **CONTENT READY / RUNTIME PENDING CODEX** | Boş Ubuntu 24.04 üzerinde sıfırdan adım adım manuel kurulum kılavuzu ve 11 otomasyon scripti. |
| `LAB-LNX-01` | Linux Preflight | YES | YES | YES | YES | YES | `docker` / Port 22 | `preflight_check.sh` çıkış kodu 0 olmalı | **CONTENT READY / RUNTIME PENDING CODEX** | Ubuntu 24.04 cgroups v2 ve port denetimleri eksiksiz. |
| `LAB-GIT-01` | Git Workflow | YES | YES | YES | YES | YES | `docker` / - | Merge conflict çözümü ve `jq .` kontrolü | **CONTENT READY / RUNTIME PENDING CODEX** | Otomatik çakışma üreten simülasyon scripti dahil. |
| `LAB-DOC-01` | First Container | YES | YES | YES | YES | YES | `docker` / `8080:80` | `curl -f http://localhost:8080` HTTP 200 | **CONTENT READY / RUNTIME PENDING CODEX** | Nginx 1.27-alpine ile port yönlendirmesi doğrulanır. |
| `LAB-DOC-02` | Volumes & Env | YES | YES | YES | YES | YES | `docker` / `5432:5432` | Postgres volume kalıcılık testi (2 kayıt) | **CONTENT READY / RUNTIME PENDING CODEX** | Konteyner silinip yeniden başlatıldığında veri kaybı olmaz. |
| `LAB-DOC-03` | Layer Caching | YES | YES | YES | YES | YES | `docker` / `8000:8000` | İkinci build `CACHED` ve HTTP 200 | **CONTENT READY / RUNTIME PENDING CODEX** | `.dockerignore` ve katman sıralaması optimize edilmiştir. |
| `LAB-DOC-04` | Multi-Stage | YES | YES | YES | YES | YES | `docker` / `3000:3000` | Non-root `UID 10001` ve imaj boyutu ~160MB | **CONTENT READY / RUNTIME PENDING CODEX** | Node.js 20-alpine TypeScript build aracı runtime'a taşınmaz. |
| `LAB-DOC-05` | Compose Multi-Tier| YES | YES | YES | YES | YES | `docker` / `8080,5432,6379`| Tüm servisler `healthy` ve sayaç artışı | **CONTENT READY / RUNTIME PENDING CODEX** | `service_healthy` bağımlılık zinciri eksiksizdir. |
| `LAB-DOC-06` | Trivy & Harbor | YES | YES | YES | YES | YES | `docker` / `8082:8082` | Trivy exit code 0 ve Harbor tagleme | **CONTENT READY / RUNTIME PENDING CODEX** | Fragile CVE sayısı yerine dinamik `>=1` zafiyet gösterilmiştir. |
| `LAB-JNK-01` | Declarative CI | YES | YES | YES | YES | YES | `jenkins-ci` / `8080:8080` | JUnit XML 5/5 passed | **CONTENT READY / RUNTIME PENDING CODEX** | Jenkins 2.568.2 LTS Declarative Pipeline as Code. |
| `LAB-JNK-02` | Secure Pipeline | YES | YES | YES | YES | YES | `secure-ci` / `8080,9000,8082`| Sonar Quality Gate OK, Trivy 0 CRITICAL | **CONTENT READY / RUNTIME PENDING CODEX** | SonarQube 26.8.0.126808-community ve Harbor 2.15.2. |
| `LAB-GLB-01` | GitLab CI | YES | YES | YES | YES | YES | `gitlab-ci` / `8081:80` | YAML syntax lint ve npm test exit 0 | **CONTENT READY / RUNTIME PENDING CODEX** | GitLab CE 17.9.3 ve Runner alpine-v17.9.1 tam major.minor uyumu. |
| `LAB-TF-01` | Terraform Local | YES | YES | YES | YES | YES | `docker` / `8090:80` | `terraform apply` 3 added, HTTP 200 | **CONTENT READY / RUNTIME PENDING CODEX** | Terraform 1.16.0 ve `kreuzwerker/docker` provider ile deklaratif IaC. |
| `LAB-K8S-01` | kind Multi-Node | YES | YES | YES | YES | YES | `kubernetes` / `80,443,8088`| 3 nodes Ready, 3/3 pod running, Headlamp v0.45| **CONTENT READY / RUNTIME PENDING CODEX** | Kubernetes v1.31.9 SHA256 digest pini, `kubeadm.k8s.io/v1beta4`. |
| `LAB-K8S-02` | Services & Config| YES | YES | YES | YES | YES | `kubernetes` / DNS internal | CoreDNS sorgusu ile pod içi HTTP 200 | **CONTENT READY / RUNTIME PENDING CODEX** | ClusterIP, ConfigMap ve Secret ortam değişkeni olarak bağlanır. |
| `LAB-K8S-03` | Probes & Rollout | YES | YES | YES | YES | YES | `kubernetes` / Ingress | RollingUpdate kesintisiz geçiş, PVC bound | **CONTENT READY / RUNTIME PENDING CODEX** | Liveness/Readiness probları, Burstable QoS limitleri. |
| `LAB-HLM-01` | Helm Packaging | YES | YES | YES | YES | YES | `kubernetes` / Internal | `helm lint` 0 failure, 4 replika ayağa kalkar | **CONTENT READY / RUNTIME PENDING CODEX** | Helm v3.21.0 parametrik `values.yaml` ve rollback pratiği. |
| `LAB-ARG-01` | Argo CD GitOps | YES | YES | YES | YES | YES | `kubernetes` / `8085:443` | Application `Synced & Healthy`, drift heal | **CONTENT READY / RUNTIME PENDING CODEX** | Argo CD 3.4.2; `targetRevision: main`. |
| `LAB-MON-01` | Prometheus Metrics| YES | YES | YES | YES | YES | `monitoring` / `9090,3000,9100`| Prometheus 3 targets `UP`, PromQL rate > 0 | **CONTENT READY / RUNTIME PENDING CODEX** | Prometheus 3.13 LTS ve Grafana 13.1.5 Golden Signals paneli. |
| `LAB-MON-02` | Alertmanager Rules| YES | YES | YES | YES | YES | `monitoring` / `9090,9093` | `ServiceDown` alarmı `firing` durumuna geçer | **CONTENT READY / RUNTIME PENDING CODEX** | Alertmanager v0.33 API v2 yönlendirmesi ve susturma mekanizması. |
| `LAB-LOG-01` | Central Logging | YES | YES | YES | YES | YES | `logging` / `9200,5601` | ES bulk indekste en az 1 JSON log kaydı | **CONTENT READY / RUNTIME PENDING CODEX** | Elasticsearch 8.17.8, Kibana 8.17.8 ve Vector 0.40.2-alpine. |
| `LAB-INC-01` | Incident Response| YES | YES | YES | YES | YES | `kubernetes` / Internal | 3 pod Running yapılır, postmortem raporu tam | **CONTENT READY / RUNTIME PENDING CODEX** | CrashLoopBackOff, ImagePullBackOff ve Flapping Probe kök neden analizi. |
| `LAB-CAP-01` | End-to-End Capstone| YES | YES | YES | YES | YES | `phased` / `8000,8082` | `ci_pipeline_runner.sh` 5/5 aşamayı geçer | **CONTENT READY / RUNTIME PENDING CODEX** | Git commit -> Unit test -> Sonar -> Trivy -> Harbor -> K8s -> Telemetry. |

---

## 2. Kalite ve Bütünlük Kontrol Listesi Özeti

- [x] **11 Standart Bölüm Mimarisi:** 22 zorunlu labın tamamı istisnasız 11 zorunlu bölüm sırasına (`1. Lab Senaryosu` ... `11. Challenge`) tam uyumludur.
- [x] **Profesyonel Hands-on Dil Standardı:** Sınıfı dışarıdan anlatan meta ifadeler ("Öğrenci şunu yapar", "Eğitmen gösterir", "Katılımcı uygular") ve amatör dolgu ifadeleri ("harika!", "tebrikler", vb.) tüm student-facing lab metinlerinden %100 temizlenmiştir; doğrudan teknik emir/uygulama dili ("çalıştırın", "doğrulayın") kullanılmıştır.
- [x] **Kırık Link / Yol Yok:** Tüm referanslar doğrulanmış gerçek markdown dosyalarına (`labs/...`) işaret etmektedir.
- [x] **Tutarlı Lab ID'leri:** 22 zorunlu labın kodları kataloğun tüm dosyalarında (`01` ila `17`) birebir eşleşmektedir.
- [x] **Doğru Önkoşullar & Bağımlılıklar:** Hiçbir labda henüz öğrenilmemiş bir aracın bilgisi şart koşulmamıştır.
- [x] **Çakışmasız Port ve Profil Bütçesi:** Aynı anda çalışan servisler için port çakışması sıfırlanmış, RAM bütçesi maksimum 4.5 GB ile sınırlandırılmıştır.
- [x] **Temizlik ve Doğrulama Garantisi:** 22 labın 22'sinde de `Validation`, `Cleanup` ve `Reset` komutları yer almaktadır.
- [x] **Sıfır Mock / Sahte Adım:** Yorum satırına alınmış kod, `echo "docker push"` veya sahte Sonar onayı tamamen tasfiye edilmiştir.
- [x] **Normal Akışta `:latest` Yok:** Tüm imajlar (`node:20-alpine`, `nginx:1.27-alpine`, `curlimages/curl:8.10.1`, vb.) sabit taglidir.
- [x] **Argo CD Öğrenci Reposunu İzler:** Dış GitHub reposu veya `HEAD` referansı yerine öğrencinin `main` dalındaki deklaratif manifestoları izlenir.
- [x] **Gerçekçi Zaman Bütçesi:** Günlük süreler 5.5 - 6.0 saat arasında tutulmuş, 09:00 - 17:00 eğitim saatlerine tam olarak sığdırılmıştır.

