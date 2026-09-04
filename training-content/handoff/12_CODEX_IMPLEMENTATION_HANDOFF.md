# 12 — CODEX PLATFORM UYGULAMA TESLİM REHBERİ (IMPLEMENTATION HANDOFF)

## 1. Genel Bilgilendirme ve Mimari Sınırlar

Gemini, bu çalışma paketinde **Müfredat Mimarı, Lab Tasarımcısı ve QA İnceleyicisi** olarak görev yapmıştır. Çalışan merkezi platform kodlarının (`Terraform / GCP / Cloudflare / Ansible`) ve öğrenci sunucusu otomasyonlarının implementation sahibi **Codex**'tir.

Bu doküman, Codex'in lab ve proje varlıklarını (`lab-assets`) platforma hatasız entegre edebilmesi için gereken tüm teknik teslim spesifikasyonlarını (Handoff Specifications) ve **2026 Training-Stable Compatibility Pin** değerlerini içerir.

> [!IMPORTANT]
> **CODEX İÇİN BAĞLAYICI İÇERİK KORUMA VE UYGULAMA KURALLARI (MANDATORY BINDING DIRECTIVES):**
> 
> Gemini tarafından üretilen 22 zorunlu lab dokümanı **FINAL CONTENT** olarak kabul edilmiştir. Codex bu dokümanları ana repository veya portala aktarırken aşağıdaki kurallara kesinlikle uymakla yükümlüdür:
> 
> 1. **İçerik ve Dil Dokunulmazlığı (Do Not Rewrite):**
>    - Anlatım dilini yeniden yazmayın.
>    - 11 standart bölüm yapısını değiştirmeyin veya başlıkların sırasını bozmayın.
>    - Metinlere kesinlikle *"öğrenci", "eğitmen", "katılımcı", "instructor", "student"* gibi meta ve anlatıcı ifadeleri geri eklemeyin.
>    - Gereksiz açıklama, dolgu (filler) metinleri veya yapay motivasyon ifadeleri (*"harika", "tebrikler"*) eklemeyin.
>    - Lab senaryolarını veya pedagojik kurguları değiştirmeyin.
> 
> 2. **Codex'in Gerçek Görev Alanı (Codex Implementation Scope):**
>    - Dokümanları hedef ana repository ve portal dizin yapısına yerleştirmek.
>    - `outputs/lab-assets/` altındaki starter/solution ve script varlıklarını (`starter/`, `solution/`, `scripts/`) oluşturmak.
>    - Gerçek sunucu/runtime ortamında komutları headless olarak çalıştırmak ve test etmek.
>    - Çalışma zamanında ortaya çıkan gerçek teknik/sürüm hataları varsa düzeltmek.
>    - `validate.sh` ve `cleanup.sh` scriptlerinin fiziksel ortamdaki doğruluğunu ve çıkış kodlarını test etmek.
>    - Endpoint, port, IP, domain ve dosya yolu gibi runtime değerlerini gerçek platform konfigürasyonuyla birebir eşleştirmek.
> 
> 3. **Teknik Düzeltmelerde Pedagojik Bütünlük Kuralı:**
>    - Çalışma zamanı kaynaklı zorunlu bir teknik düzeltme gerektiğinde pedagojik metni, komut sırasını ve açıklama bütünlüğünü mümkün olduğunca aynen koruyun.
> 
> **Student-Facing Nihai 11 Bölüm Formatı:**
> 1. Lab Senaryosu
> 2. Amaç
> 3. Mimari / Akış
> 4. Ön Koşullar
> 5. Adım Adım Uygulama
> 6. Beklenen Sonuç
> 7. Doğrulama
> 8. Sorun Giderme
> 9. Temizlik / Sıfırlama
> 10. Production Notu
> 11. Challenge


---

## 2. Lab Implementation Spesifikasyonları ve 2026 Sürüm Sabitlemeleri

| Lab ID | Hedef Dizin (Target Path) | 2026 Sabitlenmiş İmajlar & Sürümler | Host Portları | Profil | Doğrulama & Temizlik Davranışı |
|---|---|---|---|---|---|
| `LAB-ENV-00` | `labs/LAB-ENV-00/` | Full 2026 Training Toolchain (Manual + Scripts) | Tüm Portlar | `docker` | `validate-environment.sh` -> 0 FAIL. |
| `LAB-LNX-01` | `labs/LAB-LNX-01/` | Linux Native (`ss`, `lsof`, `systemd`, `cgroups v2`) | - | `docker` | `scripts/preflight_check.sh` -> Exit 0. |
| `LAB-GIT-01` | `labs/LAB-GIT-01/` | Git 2.44+, `jq 1.7+` | - | `docker` | `jq . app-config.json` -> Exit 0, merge conflict çözümü. |
| `LAB-DOC-01` | `labs/LAB-DOC-01/` | `nginx:1.27-alpine` | `8080:80` | `docker` | `curl -f http://localhost:8080` -> HTTP 200. Cleanup: `docker rm -f`. |
| `LAB-DOC-02` | `labs/LAB-DOC-02/` | `postgres:16.4-alpine` | `5432:5432` | `docker` | `psql` ile tablo kaydı 2 dönmeli (Volume kalıcılığı). |
| `LAB-DOC-03` | `labs/LAB-DOC-03/` | `python:3.11-slim-bookworm` | `8000:8000` | `docker` | İkinci build `CACHED` olmalı, `curl http://localhost:8000/healthz` -> 200. |
| `LAB-DOC-04` | `labs/LAB-DOC-04/` | `node:20-alpine` | `3000:3000` | `docker` | `docker exec id -u` == 10001 (Non-root) ve HTTP 200. |
| `LAB-DOC-05` | `labs/LAB-DOC-05/` | `postgres:16.4-alpine`, `redis:7.4-alpine`, Python | `8080:8080` | `docker` | `compose.yaml` -> tüm servisler `healthy`, Redis sayaç artışı. |
| `LAB-DOC-06` | `labs/LAB-DOC-06/` | `aquasec/trivy:0.74.0`, `node:20-alpine`, Harbor 2.15 | `8082:8082` | `docker` | Trivy CRITICAL = 0, Exit Code 0, Harbor tag. |
| `LAB-JNK-01` | `labs/LAB-JNK-01/` | `jenkins/jenkins:2.568.2-lts-jdk17`, `python3-venv` | `8080:8080` | `jenkins-ci`| `junit-report.xml` dosyasında 5 test passed. |
| `LAB-JNK-02` | `labs/LAB-JNK-02/` | `sonarqube:26.8.0.126808-community`, `aquasec/trivy:0.74.0` | `9000:9000` | `secure-ci` | Quality Gate = OK, Trivy = 0 CRITICAL. |
| `LAB-GLB-01` | `labs/LAB-GLB-01/` | `gitlab/gitlab-ce:17.9.3-ce.0`, `gitlab/gitlab-runner:alpine-v17.9.1` | `8081:80` | `gitlab-ci` | `.gitlab-ci.yml` lint doğrulaması ve `npm test` exit 0. |
| `LAB-TF-01` | `labs/LAB-TF-01/` | `terraform:1.16.0`, `kreuzwerker/docker:3.0.2`| `8090:80` | `docker` | `terraform apply` -> 3 added, `curl http://localhost:8090` -> 200. |
| `LAB-K8S-01` | `labs/LAB-K8S-01/` | `kind:v0.30.0`, `kindest/node:v1.31.9@sha256:b94a...`, `Headlamp:v0.45.0` | `80, 443, 8088`| `kubernetes`| 3 kind node Ready, 3/3 pod running, Headlamp responsive. |
| `LAB-K8S-02` | `labs/LAB-K8S-02/` | `curlimages/curl:latest`, `hashicorp/http-echo` | - | `kubernetes`| ClusterIP DNS sorgusu ile pod içi iletişim testi HTTP 200. |
| `LAB-K8S-03` | `labs/LAB-K8S-03/` | `hashicorp/http-echo:0.2.3`, Local PV | - | `kubernetes`| RollingUpdate kesintisiz geçiş, rollback başarı, PVC Bound. |
| `LAB-HLM-01` | `labs/LAB-HLM-01/` | `helm:v3.21.0` | - | `kubernetes`| `helm lint` -> 0 failed, 4 replikalı prod release deployed. |
| `LAB-ARG-01` | `labs/LAB-ARG-01/` | `argoproj/argo-cd:v3.4.2` | `8085:443` | `kubernetes`| Argo CD App `Synced & Healthy`, drift self-healed. |
| `LAB-MON-01` | `labs/LAB-MON-01/` | `prom/prometheus:v3.13.2`, `grafana/grafana:13.1.5` | `9090, 3000` | `monitoring` | Prometheus 3.x LTS 3 target `UP`, PromQL rate > 0. |
| `LAB-MON-02` | `labs/LAB-MON-02/` | `prom/alertmanager:v0.33.0` | `9093:9093` | `monitoring` | `ServiceDown` alarmı `firing` durumuna geçer. |
| `LAB-LOG-01` | `labs/LAB-LOG-01/` | `elasticsearch:8.17.8`, `kibana:8.17.8`, `vector:0.40.2`| `9200, 5601` | `logging` | JSON loglar ES 8.17 indeksine yazılır, Kibana dashboard hazır. |
| `LAB-INC-01` | `labs/LAB-INC-01/` | `busybox:1.36`, `nginx:1.27-alpine` | - | `kubernetes`| 3 arızalı pod düzeltilir, `postmortem.md` üretilir. |
| `LAB-CAP-01` | `labs/LAB-CAP-01/` | Full 2026 Training-Stable DevOps Stack (7 Profil)| `8000, 8082` | `phased` | `ci_pipeline_runner.sh` tüm 5 aşamayı yeşil tamamlar. |

---

## 3. Codex İçin Klasör ve Varlık Yapısı Standardı (Asset Tree)

Codex implementation yaparken `outputs/lab-assets/` altında aşağıdaki dizin standardını korumalıdır:

```text
outputs/lab-assets/LAB-XXX/
├── starter/              # Öğrenciye ilk verilen eksik/şablon dosyalar
│   ├── Dockerfile
│   └── compose.yaml
├── solution/             # Tam çalışan referans çözüm dosyaları
│   ├── Dockerfile
│   └── compose.yaml
└── scripts/
    ├── validate.sh       # Otomatik PASS/FAIL testi koşturan script
    ├── cleanup.sh        # Lab bitiminde kaynakları temizleyen script
    └── reset.sh          # Öğrenci tıkandığında ortamı sıfırlayan script
```

---

## 4. Kabul Kriterleri (Codex Acceptance Criteria)

1. **Sabit Tag Kuralı:** Asla `:latest` tagi kullanılmamalıdır; tabloda belirtilen 2026 versiyon pinleri birebir uygulanmalıdır.
2. **Kullanıcı Etkileşimsiz Çalışma:** Tüm scriptler `set -euo pipefail` ve otomasyon bayrakları ile başından sonuna kadar headless çalışmalıdır.
3. **Kapsamlı Temizlik:** Her `cleanup.sh` scripti çalıştırıldığında `docker ps` ve `kubectl get pods` üzerinde ilgili laba ait hiçbir artık süreç kalmamalıdır.
