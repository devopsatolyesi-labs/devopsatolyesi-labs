# Gerçek Dünya Projesi: Python Flask Uçtan Uca CI/CD Hattı

## Metadata
- **Proje:** Python Flask Mikroservis Teslimat Hattı
- **İlişkili Jenkins İşleri:**
  - `Projects/python-flask/ci` (Sürekli Entegrasyon)
  - `Projects/python-flask/cd` (Sürekli Dağıtım)
- **Jenkins URL:** [https://jenkins.devopsatolyesi.com](https://jenkins.devopsatolyesi.com)
- **Hedef Çalışma Ortamı:** `training-ci-01` (Docker Runtime) / `training-runtime-01` (Kubernetes & Kind)
- **Dağıtılan Uygulama Portu:** `http://localhost:8089` (Canlı Servis)

---

## 1. Proje Mimarisi ve Akış Şeması

Bu proje, gerçek bir kurumsal üretim ortamında uygulanan iki aşamalı (CI ve CD ayrımı) pipeline mimarisini simüle eder. CI hattı değişmez bir artifact (immutable artifact) üretir ve doğrular; CD hattı ise bu doğrulanmış artifact'ı hedef ortama konuşlandırır ve duman testleri (smoke test) ile canlılığını denetler.

![Jenkins Python Flask CI/CD Hattı](images/python-flask-pipeline.svg)

---

## 2. CI Hattı Bileşenleri (`Projects/python-flask/ci`)

CI hattı aşağıdaki adımları sırayla icra eder:
1. **Checkout Application:** Güncel kaynak kodlar çekilir.
2. **Metadata:** Benzersiz ve değişmez imaj etiketi üretilir (`BUILD_NUMBER-GIT_SHA`).
3. **Automated Unit Tests:** Kod, izole bir test konteyneri içinde `pytest` ile test edilir. Testler geçmeden bir sonraki adıma izin verilmez.
4. **Docker Build:** Alpine tabanlı, non-root (`USER 10001`), sağlık kontrolü tanımlanmış üretim imajı derlenir.
5. **Trivy CVE Security Gate:** İmaj yerel docker daemon üzerinden taranır. Yüksek ve kritik zafiyetler denetlenir.
6. **Trigger Downstream CD:** Başarılı olan değişmez imaj etiketi parametre olarak `Projects/python-flask/cd` işine aktarılır.

---

## 3. CD Hattı Bileşenleri (`Projects/python-flask/cd`)

CD hattı "Tekrar Derleme Yapma" (Never Rebuild) prensibiyle çalışır:
1. **Validate Artifact:** `IMAGE_TAG` parametresinin dolu olduğu ve doğrulanmış imajın varlığı teyit edilir.
2. **Deploy Container:** Eski konteyner durdurulur ve yeni sürüm `8089:8080` port eşlemesiyle ayağa kaldırılır.
3. **Smoke Test & Healthcheck:** `curl -fsS http://localhost:8089/health` ve `/version` uç noktalarına istek atılır. Servis sağlıklı yanıt verene kadar doğrulanır.
4. **Otomatik Rollback:** Dağıtım veya sağlık testi başarısız olursa, bir önceki kararlı sürüme otomatik geri dönüş sağlanır.

---

## 4. Adım Adım Çalıştırma ve Canlı Doğrulama

1. [https://jenkins.devopsatolyesi.com](https://jenkins.devopsatolyesi.com) adresine gidin.
2. **Projects** -> **python-flask** -> **ci** işini açın.
3. **Build with Parameters** seçeneğine tıklayın.
   - `IMAGE_NAME`: `devops-atolyesi/python-flask`
   - `TRIVY_ENABLED`: `true`
   - `CD_JOB_NAME`: `Projects/python-flask/cd`
4. **Build** butonuna basın.

### Konsol Takibi:
- Testlerin çalıştığını ve geçtiğini gözlemleyin:
  ```text
  Running Pytest Test Suite inside container...
  3 passed in 0.49s
  ```
- Trivy güvenlik kapısının aşıldığını görün:
  ```text
  Scanning Image for High/Critical CVEs...
  Trivy scan passed.
  ```
- Downstream CD işinin otomatik tetiklendiğini görün:
  ```text
  Triggering downstream CD deployment job: Projects/python-flask/cd
  Starting building: Projects » python-flask » cd #1
  Build Projects » python-flask » cd #1 completed: SUCCESS
  ```

---

## 5. Canlı Servisi Test Etme

CD işi tamamlandıktan sonra uygulamanın `/health` ve `/version` uç noktalarını doğrudan test edebilirsiniz:

```bash
# Canlı sağlık durumu kontrolü
curl -s http://localhost:8089/health
# Yanıt: {"status":"healthy"}

# Canlı sürüm ve ortam bilgisi
curl -s http://localhost:8089/version
# Yanıt: {"environment":"training","version":"..."}
```
