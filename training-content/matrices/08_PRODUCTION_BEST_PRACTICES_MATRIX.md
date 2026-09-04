# 08 — ÜRETİM ORTAMI EN İYİ PRATİKLERİ MATRİSİ (PRODUCTION BEST PRACTICES)

Bu doküman, 5 günlük **DevOps Practitioner** eğitimi boyunca işlenen 10 temel mimari disiplinin üretim standartlarını (Production Standards), anti-pattern'lerini (kaçınılması gereken hatalar), uygulama yöntemlerini ve ilgili lab referanslarını sunar.

---

## 1. Çapraz Kesitli En İyi Pratikler Matrisi

| Disiplin | Üretim Standardı (Do This) | Anti-Pattern (Don't Do This) | Uygulama Yöntemi | Lab Referansı |
|---|---|---|---|---|
| **1. Konteyner Güvenliği** | Non-root kullanıcı (`UID 10001`), Multi-stage build, Minimal base image (Alpine/Distroless). | Konteyneri `root` olarak çalıştırmak, derleme araçlarını runtime imajında bırakmak. | `USER 10001:10001`, `RUN adduser -u 10001 ...` | `LAB-DOC-04`, `LAB-DOC-07` |
| **2. En Düşük Yetki (Least Privilege)** | Linux'ta kısıtlı `sudoers`, K8s'te kısıtlı `Role/RoleBinding`, Konteynerde `allowPrivilegeEscalation: false`. | Her şeye `cluster-admin` vermek, herkese tam root yetkisi vermek. | `securityContext`, `kubectl auth can-i` | `LAB-LNX-02`, `LAB-K8S-11`, `LAB-SEC-03` |
| **3. Sağlık Kontrolleri (Health Probes)** | `startupProbe` (yavaş servisler için), `readinessProbe` (trafik için), `livenessProbe` (yeniden başlatma için). | Probları tamamen atlamak veya liveness'a ağır DB sorgusu bağlamak. | HTTP/TCP probları, `initialDelaySeconds`, `failureThreshold` | `LAB-DOC-05`, `LAB-K8S-03`, `LAB-INC-01` |
| **4. Kaynak Sınırları & QoS** | Her konteyner için `requests` ve `limits` zorunlu; `Burstable` veya `Guaranteed` QoS. | Limitsiz pod çalıştırmak (Noisy Neighbor ve OOM riski yaratmak). | `resources: requests/limits: cpu, memory` | `LAB-DOC-10`, `LAB-K8S-03`, `LAB-INC-03` |
| **5. Değişmez Artefaktlar (Immutability)** | Pinned Git commit SHA veya semantik versiyon (`v1.2.3`), İmzalı imajlar. | Üretimde `:latest` tag kullanmak, mutable image üzerine deploy çıkmak. | Harbor tag retention & immutability kuralları, Cosign | `LAB-DOC-06`, `LAB-JNK-02`, `LAB-GLB-01` |
| **6. Gizli Anahtar Yönetimi (Secrets)** | Centralized Secret Store (Vault, AWS SM, External Secrets), Secret masking. | Şifreleri Git'e commit etmek, Dockerfile içine `ENV PASSWORD=...` gömmek. | Gitleaks pre-commit hook, K8s External Secrets Operator | `LAB-GIT-03`, `LAB-SEC-01`, `LAB-K8S-02` |
| **7. Kalite & Güvenlik Kapıları** | CI pipeline'ında zorunlu SonarQube Quality Gate ve Trivy CRITICAL CVE blocker. | Hata veya güvenlik uyarısına rağmen pipeline'ı zorla yeşil geçirmek (`\|\| true`). | `trivy image --exit-code 1`, `waitForQualityGate()` | `LAB-DOC-06`, `LAB-JNK-02`, `LAB-GLB-04` |
| **8. Dağıtım & Geri Alma (Rollback)** | Zero-downtime RollingUpdate (`maxSurge: 1, maxUnavailable: 0`), GitOps `git revert`. | Manuel `kubectl edit` yapmak, kesintili doğrudan pod silerek güncelleme. | `kubectl rollout undo`, `helm rollback`, Argo CD self-heal | `LAB-K8S-03`, `LAB-HLM-01`, `LAB-ARG-04` |
| **9. Gözlemlenebilirlik (Observability)** | The 4 Golden Signals (Latency, Traffic, Errors, Saturation), Yapılandırılmış JSON loglar, Actionable Alerts. | Unstructured düz metin log basmak, sürekli çalan anlamsız alarmlar (Alert Fatigue). | Prometheus PromQL, FluentBit/Vector, Alertmanager runbooks | `LAB-MON-01`, `LAB-MON-02`, `LAB-LOG-01` |
| **10. Kriz & Hata Yönetimi** | Sistematik teşhis (`describe`, `logs --previous`), Blameless Postmortem kültürü, 5-Whys. | Körlemesine pod restart etmek, suçlu aramak, arızayı dokümante etmemek. | Postmortem Raporlama, MTTR düşürme metrikleri | `LAB-INC-01`, `PROJECT-09` |

---

## 2. Kurumsal Üretim Kontrol Listesi (Production Readiness Checklist)

Bir uygulama veya mikroservis üretim ortamına (Kubernetes / Cloud) alınmadan önce aşağıdaki 8 maddeyi eksiksiz sağlamalıdır:

- [ ] **1. Image Hardening:** Multi-stage derleme yapılmış, non-root (`UID 10001`) kullanıcı tanımlanmış, Trivy taramasında 0 CRITICAL CVE onaylanmıştır.
- [ ] **2. Resource Guardrails:** CPU/Memory için hem `requests` hem `limits` belirlenmiş, düğüm kapasitesine uygun ayarlanmıştır.
- [ ] **3. Dual Probes:** Hem `readinessProbe` (trafik kesme) hem `livenessProbe` (yeniden başlatma) tanımlanmıştır.
- [ ] **4. High Availability:** En az 2 replika tanımlanmış ve `podAntiAffinity` ile farklı düğümlere dağıtılmıştır.
- [ ] **5. Graceful Termination:** Konteyner SIGTERM sinyalini yakalayarak açık kalan HTTP/DB bağlantılarını temizlemektedir (`terminationGracePeriodSeconds: 30`).
- [ ] **6. GitOps Managed:** Dağıtım doğrudan elle değil, Argo CD / GitOps deposundaki versiyonlanmış manifest üzerinden yapılmaktadır.
- [ ] **7. Metrics & Logs:** Uygulama `/metrics` sunmakta ve tüm logları `trace_id` içeren JSON formatında stdout'a basmaktadır.
- [ ] **8. Actionable Alerting:** Servis için p95 gecikme ve HTTP 5xx hata oranı alarmları Alertmanager'da tanımlanmıştır.
