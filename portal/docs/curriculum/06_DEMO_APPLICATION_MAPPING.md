# 06 — DEMO UYGULAMA EŞLEŞTİRME VE KAYNAK ANALİZİ

Bu doküman, 5 günlük **DevOps Practitioner** eğitiminde kullanılan tüm demo uygulamaların teknik özelliklerini, upstream kaynaklarını, bellek/CPU bütçelerini ve ilgili lab eşleştirmelerini detaylandırır.

---

## 1. Uygulama Stratejisi ve Temel İlkeler

Eğitimin amacı yazılım geliştirme (software development) öğretmek değil; **DevOps, CI/CD, Güvenlik, Orkestrasyon ve Gözlemlenebilirlik** pratiklerini öğretmektir. Bu nedenle:
1. **Gereksiz Kodlama Yok:** Uygulamalar minimal, temiz ve anlaşılır tutulmuştur.
2. **Sabit Sürümler (Pinned Releases):** Beklenmedik kırılmaları önlemek için tüm upstream imaj ve kütüphane sürümleri sabitlenmiştir.
3. **Düşük Bellek Ayak İzi:** Öğrencinin tek bir Ubuntu sunucusunda (8-16 GB RAM) rahat çalışabilmesi için hafif imajlar (Alpine, Slim, Distroless) tercih edilmiştir.

---

## 2. Demo Uygulama Matrisi

| Uygulama Adı | Teknoloji / Dil | Upstream Kaynak & Tag | RAM İhtiyacı | Kullanıldığı Lab / Projeler |
|---|---|---|---|---|
| **devops-demo-python** | Python 3.11 / FastAPI | `python:3.11-slim-bookworm` | ~60 MB | `LAB-DOC-03`, `LAB-DOC-05`, `LAB-JNK-01`, `LAB-MON-01`, `LAB-LOG-01`, `LAB-CAP-01` |
| **devops-demo-node** | Node.js 20 / Express / TS | `node:20-alpine` | ~90 MB | `LAB-DOC-04`, `LAB-DOC-06`, `LAB-GLB-01`, `PROJECT-01`, `PROJECT-03` |
| **spring-petclinic** | Java 17 / Spring Boot 3 | `spring-projects/spring-petclinic:v3.2.0` | ~450 MB | `LAB-JNK-02`, `PROJECT-02`, Java CI & SonarQube Practitioner |
| **Google Online Boutique** | Polyglot Microservices | `GoogleCloudPlatform/microservices-demo:v0.9.0` | ~1.8 GB | `PROJECT-05`, `PROJECT-06`, Kubernetes & GitOps Showcase |
| **OpenTelemetry Astronomy Shop** | OpenTelemetry Demo | `open-telemetry/opentelemetry-demo:v1.8.0` | ~2.2 GB | `LAB-OTEL-01`, Day 5 Advanced Distributed Tracing Demo |
| **http-echo / busybox** | Go / POSIX Shell | `hashicorp/http-echo:0.2.3` / `busybox:1.36` | ~10 MB | `LAB-K8S-01`, `LAB-K8S-02`, `LAB-K8S-03`, `LAB-HLM-01`, `LAB-INC-01` |

---

## 3. Uygulama Detayları ve Mimari Rolleri

### 3.1. `devops-demo-python` (Hafif ve Çok Amaçlı Mikroservis)
- **Rolü:** Hızlı katman önbelleği (caching), unit test (pytest), healthcheck endpointleri (`/healthz`), Prometheus `/metrics` enstrümantasyonu ve yapılandırılmış JSON log üretimi.
- **Dockerfile Stratejisi:**
  - Build context `.dockerignore` ile temizlenir.
  - `requirements.txt` önce kopyalanır (`CACHED`).
  - Non-root kullanıcı (`UID 10001`) ile çalışır.
- **Portlar:** `8000` veya `8080`.

### 3.2. `devops-demo-node` (TypeScript & Multi-Stage Referansı)
- **Rolü:** Multi-stage build aşamasında derleme bağımlılıkları (`devDependencies`, `tsc`) ile çalışma zamanı (`production node_modules`) ayrımını öğretmek.
- **Dockerfile Stratejisi:**
  - Stage 1 (Builder): `node:20-alpine` -> `npm ci` -> `npm run build`
  - Stage 2 (Runner): `node:20-alpine` -> sadece derlenmiş `dist/server.js` ve prod paketler taşınır.
- **Güvenlik Çıktısı:** 1.2 GB'lık node imajı ~150 MB'a iner ve CVE sayısı sıfırlanır.

### 3.3. `spring-petclinic` (Kurumsal Java & SonarQube Referansı)
- **Rolü:** Kurumsal dünyadaki Java iş yüklerini, Maven derleme aşamalarını, derinlemesine SonarQube statik analizini ve Spring Boot Actuator metriklerini simüle etmek.
- **Kaynak Tüketimi:** JVM belleği `-Xms256m -Xmx384m` ile sınırlandırılır.

### 3.4. `Google Online Boutique` (Mikroservis & GitOps Şaheseri)
- **Rolü:** 11 bağımsız servisten (Frontend, Cart, Payment, Currency, Recommendation vb.) oluşan gerçek dünya e-ticaret uygulaması.
- **Eğitimde Kullanımı:** Öğrenci sunucusunda aşırı RAM tüketimini önlemek için tam set yerine 3-4 çekirdek servis (Frontend + Cart + Redis + Currency) kullanılır; tam set eğitmen tarafından `devopsatolyesi.com` üzerinde canlı gösterilir.

### 3.5. `OpenTelemetry Astronomy Shop` (Observability & Tracing)
- **Rolü:** Dağıtık izleme (Distributed Tracing), OpenTelemetry Collector, Jaeger ve Prometheus metrik korelasyonunu göstermek için eğitmen referans platformu (SEE IT) olarak kullanılır.
