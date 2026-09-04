# 07 — ARIZA TEŞHİS VE ÇÖZÜM REHBERİ (TROUBLESHOOTING POOL)

Bu doküman, 5 günlük **DevOps Practitioner** eğitiminde öğrencilerin ve mühendislerin karşılaşabileceği en yaygın **17 gerçek üretim arıza senaryosunu**; semptom, delil toplama, teşhis komutları, kök neden analizi, onarım adımları, doğrulama ve önleme prensipleri ile detaylandırır.

---

## Arıza Senaryoları İndeksi

| Senaryo ID | Kategori | Arıza Başlığı | Semptom & Hata Kodu |
|---|---|---|---|
| `SCEN-01` | Docker | Container Exited (Code 0 / 1) | `Exited (0)` veya `Exited (1)` hemen kapanma |
| `SCEN-02` | Network / Host | Host Port Already Allocated | `bind: address already in use` |
| `SCEN-03` | Docker Permissions | Docker Daemon Socket Permission Denied | `Got permission denied ... unix:///var/run/docker.sock` |
| `SCEN-04` | Docker Build | Stale Build Cache & Unused Layers | Kod değiştiği halde eski kütüphanenin koşması |
| `SCEN-05` | Jenkins | Credentials Binding Failure | `Secret text not found` / Unmasked secret in logs |
| `SCEN-06` | SonarQube | Quality Gate Timeout / Failure | `Timeout waiting for quality gate` / Status FAILED |
| `SCEN-07` | Harbor / Registry | Harbor Push Denied / TLS Error | `x509: certificate signed by unknown authority` |
| `SCEN-08` | GitLab | GitLab Runner Offline | `Job is stuck because the runner is offline` |
| `SCEN-09` | GitLab CI | CI Variable Expansion & Masking | `Unmasked variable contains illegal characters` |
| `SCEN-10` | Kubernetes | Pod CrashLoopBackOff | `CrashLoopBackOff` (Restart count artıyor) |
| `SCEN-11` | Kubernetes | Pod ImagePullBackOff | `ImagePullBackOff` / `ErrImagePull` |
| `SCEN-12` | Kubernetes | Service Endpoint Empty / Flapping | `Service has no active endpoints (503 Service Unavailable)` |
| `SCEN-13` | Kubernetes | Pod OOMKilled (Exit Code 137) | `OOMKilled: Terminated with Exit Code 137` |
| `SCEN-14` | GitOps / Argo | Argo CD OutOfSync / SyncFailed | `OutOfSync` / `Immutable field cannot be modified` |
| `SCEN-15` | Prometheus | Prometheus Target State DOWN | `Target State: DOWN (Connection Refused / Timeout)` |
| `SCEN-16` | Elasticsearch | ES Memory & vm.max_map_count | `max virtual memory areas vm.max_map_count is too low` |
| `SCEN-17` | Kibana / Logs | Kibana Data View Empty | `No results found in selected time range` |

---

## Detaylı Arıza Analizleri

### SCEN-01: Container Immediately Exits with Code 0 or 1
* **Symptom:** Konteyner `docker run -d` ile başlatıldıktan 1 saniye sonra `docker ps` çıktısında görünmez; `docker ps -a` çıktısında `Exited (0)` veya `Exited (1)` görünür.
* **Evidence:** `docker logs <container_name>` çalıştırıldığında çıktı boştur veya `process finished` yazar.
* **Likely Causes:**
  - PID 1 olarak çalışan ana işlem (örn. `nginx`, `node`, `python`) arka planda (daemon/fork) başlatılmış ve foreground'da tutacak işlem kalmamıştır.
  - Başlangıç parametresi veya ortam değişkeni eksiktir.
* **Diagnostic Commands:**
  ```bash
  docker ps -a --filter "name=<container>"
  docker logs --tail 50 <container>
  docker inspect <container> --format '{{.State.ExitCode}} - {{.State.Error}}'
  ```
* **Root Cause:** NGINX `daemon on;` modunda başlatılmış veya `CMD` satırında foreground işlemi verilmemiştir.
* **Fix:** Dockerfile içindeki CMD'yi foreground moduna ayarlayın: `CMD ["nginx", "-g", "daemon off;"]`.
* **Verification:** `docker ps` çıktısında konteynerin `Up X minutes` durumunda kaldığını doğrulayın.
* **Prevention:** Konteynerlerin PID 1 felsefesini öğrenin; PID 1 süreci sonlandığında konteyner ölür.

---

### SCEN-02: Host Port Already Allocated (Address Already in Use)
* **Symptom:** Konteyner veya servis başlatılırken `Error response from daemon: driver failed programming external connectivity on endpoint ...: bind: address already in use` hatası alınır.
* **Evidence:** Belirtilen host portu (örn. `8080` veya `5432`) başka bir process tarafından dinlenmektedir.
* **Likely Causes:**
  - Daha önceden başlatılmış ve silinmemiş bir Docker konteyneri.
  - Host üzerinde çalışan yerel bir servis (örn. `systemd apache2`, `postgresql`).
* **Diagnostic Commands:**
  ```bash
  sudo ss -tulpn | grep :<port_number>
  # veya
  sudo lsof -i :<port_number>
  ```
* **Root Cause:** Aynı host portu iki farklı işleme bağlanmaya çalışılmıştır.
* **Fix:**
  ```bash
  # Çakışan işlemi sonlandırın:
  sudo kill -9 <PID>
  # Veya çakışan Docker konteynerini durdurun:
  docker rm -f <conflicting_container>
  ```
* **Verification:** `sudo ss -tulpn | grep :<port_number>` çıktısının temiz olduğunu görün.
* **Prevention:** Port matrisini (`outputs/13_RESOURCE_AND_PORT_MATRIX.md`) takip edin ve port çakışmalarını profillere ayırarak yönetin.

---

### SCEN-03: Docker Permission Denied (`/var/run/docker.sock`)
* **Symptom:** Standart kullanıcı `docker ps` çalıştırdığında `Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock` hatası alır.
* **Evidence:** `ls -la /var/run/docker.sock` çıktısında grup sahipliği `docker` grubundadır ancak kullanıcı bu grupta değildir.
* **Diagnostic Commands:**
  ```bash
  id
  groups $USER
  ls -la /var/run/docker.sock
  ```
* **Root Cause:** Kullanıcı `docker` grubuna eklenmemiştir veya yeni oturum açılmamıştır.
* **Fix:**
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker
  ```
* **Verification:** `docker version` komutunu `sudo` kullanmadan başarıyla çalıştırın.
* **Prevention:** Otomasyon scriptlerinde (Cloud-init / Ansible) kullanıcıyı doğrudan docker grubuna ekleyin.

---

### SCEN-04: Docker Build Cache Invalidation & Stale Dependencies
* **Symptom:** Kodda yapılan değişiklikler imaja yansımamakta veya `requirements.txt` / `package.json` güncellendiği halde eski bağımlılıklar çalışmaktadır.
* **Evidence:** `docker build` çıktısında `CACHED` adımları beklenmeyen yerlerde görünür.
* **Diagnostic Commands:**
  ```bash
  docker history <image_name>
  ```
* **Root Cause:** `COPY . .` satırı `RUN pip/npm install` satırından önce yazılmıştır.
* **Fix:** Dockerfile katman sırasını düzeltin (önce bağımlılık dosyasını kopyalayıp kurun, sonra kaynak kodu kopyalayın). Gerekirse `--no-cache` bayrağı ile derleyin: `docker build --no-cache -t app:v1 .`
* **Verification:** `docker inspect` ile oluşturulma zaman damgasını (Created) kontrol edin.
* **Prevention:** Dockerfile lint kurallarını (Hadolint) CI pipeline'larına dahil edin.

---

### SCEN-05: Jenkins Credentials Binding Failure & Secret Leak
* **Symptom:** Jenkins pipeline çalışırken `ERROR: Could not find credentials entry with ID 'harbor-secret'` hatası alınır veya konsol loglarında şifreler düz metin olarak basılır.
* **Evidence:** Jenkins Console Output incelendiğinde `sh: line 1: $HARBOR_PWD: unbound variable` görülür.
* **Diagnostic Commands:** Jenkins UI -> Manage Jenkins -> Credentials menüsünden ID ve Scope kontrol edilir.
* **Root Cause:** `withCredentials` bloğundaki credential ID ile Jenkins Credentials Store'daki ID uyuşmamaktadır.
* **Fix:** ID'leri eşitleyin ve şifreleri konsola `echo` ile basmaktan kaçının.
* **Verification:** Pipeline'ı tekrar koşturun; loglarda şifrenin `****` olarak maskelendiğini görün.
* **Prevention:** Tüm gizli anahtarları tek bir merkezi Secret Store (HashiCorp Vault / Jenkins Credential Store) üzerinden yönetin.

---

### SCEN-06: SonarQube Quality Gate Timeout / Webhook Failure
* **Symptom:** Jenkins pipeline `waitForQualityGate()` adımında 2-10 dakika bekleyip `Timeout waiting for quality gate` hatasıyla çöker.
* **Evidence:** SonarQube arayüzünde analiz tamamlanmış ve yeşildir ancak Jenkins durumu öğrenememiştir.
* **Diagnostic Commands:**
  ```bash
  # SonarQube webhook loglarını inceleyin
  curl -u admin:admin -X GET "http://localhost:9000/api/webhooks/deliveries"
  ```
* **Root Cause:** SonarQube -> Jenkins Webhook URL'si tanımlanmamıştır veya yanlış host/port yazılmıştır.
* **Fix:** SonarQube Administration -> Configuration -> Webhooks sekmesine `http://jenkins:8080/sonarqube-webhook/` ekleyin.
* **Verification:** Pipeline çalıştığında Quality Gate adımının 3 saniyede `OK` alarak tamamlandığını doğrulayın.
* **Prevention:** Webhook konfigürasyonlarını Terraform / SonarQube API ile otomatik provision edin.

---

### SCEN-07: Harbor Push Denied / TLS Certificate Error
* **Symptom:** `docker push localhost:5000/...` yapıldığında `http: server gave HTTP response to HTTPS client` veya `x509: certificate signed by unknown authority` hatası alınır.
* **Evidence:** Docker daemon varsayılan olarak tüm registry'lerin geçerli bir TLS sertifikasına sahip olmasını bekler.
* **Diagnostic Commands:**
  ```bash
  docker login <registry_url>
  cat /etc/docker/daemon.json
  ```
* **Root Cause:** Self-signed veya HTTP registry Docker daemon'a `insecure-registries` olarak tanıtılmamıştır.
* **Fix:**
  ```bash
  sudo tee /etc/docker/daemon.json <<EOF
  { "insecure-registries" : ["localhost:5000", "registry.devopsatolyesi.local:8082"] }
  EOF
  sudo systemctl restart docker
  ```
* **Verification:** `docker login` ve `docker push` komutlarını hatasız tamamlayın.
* **Prevention:** Üretim ortamlarında Let's Encrypt veya kurumsal CA imzalı geçerli SSL sertifikaları kullanın.

---

### SCEN-08: GitLab Runner Offline / Stuck Job
* **Symptom:** GitLab üzerinde commit atıldığında pipeline `Job is stuck. Check runners` uyarısı verir ve başlamaz.
* **Evidence:** GitLab Settings -> CI/CD -> Runners menüsünde runner simgesi gri/kırmızıdır (offline).
* **Diagnostic Commands:**
  ```bash
  sudo gitlab-runner status
  sudo gitlab-runner verify
  ```
* **Root Cause:** GitLab Runner servisi durmuştur veya kayıt tokenı süresi dolmuştur.
* **Fix:**
  ```bash
  sudo gitlab-runner restart
  sudo gitlab-runner verify --delete
  ```
* **Verification:** Runner arayüzde yeşil (active) görünmeli ve bekleyen job anında başlamalıdır.
* **Prevention:** Runner servisinin systemd üzerinden `enable` edildiğinden ve sunucu açılışında başladığından emin olun.

---

### SCEN-09: GitLab CI Variable Expansion & Masking Failure
* **Symptom:** `.gitlab-ci.yml` çalışırken `This variable cannot be masked because it contains characters not allowed in masked variables` hatası alınır.
* **Evidence:** Şifre içerisinde özel karakterler (`@`, `!`, `\n`) bulunmaktadır.
* **Diagnostic Commands:** GitLab CI/CD Variables sekmesini inceleyin.
* **Root Cause:** Masked variables sadece Base64 veya belirli alfanümerik karakter setine izin verir.
* **Fix:** Hassas veriyi Base64 ile encode edip değişkene koyun (`echo -n "$SECRET" | base64`), pipeline içinde `echo "$SECRET_B64" | base64 -d` şeklinde çözün.
* **Verification:** Pipeline hatasız tamamlanır.
* **Prevention:** Değişken tanımlarında Base64 standardını benimseyin.

---

### SCEN-10: Kubernetes Pod CrashLoopBackOff
* **Symptom:** `kubectl get pods` çıktısında Pod durumu `CrashLoopBackOff` görünür ve RESTARTS sayısı sürekli artar.
* **Evidence:** Konteyner ayağa kalkar, hata verir ve kapanır; kubelet konteyneri üstel geri çekilme (exponential backoff) ile yeniden başlatır.
* **Diagnostic Commands:**
  ```bash
  kubectl describe pod <pod_name>
  kubectl logs <pod_name> --previous
  ```
* **Root Cause:** Eksik ortam değişkeni, bağlanamayan veritabanı veya hatalı konfigürasyon dosyası.
* **Fix:** `logs --previous` çıktısındaki hatayı giderin (örn: `kubectl set env deployment/<name> DB_HOST=...`).
* **Verification:** `kubectl get pods` çıktısında Pod'un `1/1 Running` olduğunu ve restart sayısının durduğunu doğrulayın.
* **Prevention:** Konfigürasyonları ConfigMap/Secret ile standartlaştırın ve sağlık problarını doğru yapılandırın.

---

### SCEN-11: Kubernetes Pod ImagePullBackOff / ErrImagePull
* **Symptom:** Pod durumu `ImagePullBackOff` veya `ErrImagePull` olarak kalır.
* **Evidence:** `kubectl describe pod <pod>` çıktısında `Events:` altında `Failed to pull image: manifest unknown` veya `pull access denied` görülür.
* **Diagnostic Commands:**
  ```bash
  kubectl get events --sort-by='.metadata.creationTimestamp'
  kubectl describe pod <pod_name> | grep -A 5 "Events:"
  ```
* **Root Cause:**
  - İmaj etiketinde yazım hatası (typo) vardır (örn: `nginx:1.27-alpin`).
  - Özel (private) registry için `imagePullSecrets` tanımlanmamıştır.
* **Fix:**
  ```bash
  # 1. İmaj adını düzeltin:
  kubectl set image deployment/<name> <container>=nginx:1.27-alpine
  # 2. Veya Secret oluşturup deployment'a ekleyin:
  kubectl create secret docker-registry harbor-secret --docker-server=... --docker-username=... --docker-password=...
  ```
* **Verification:** Pod'un imajı çekip `Running` durumuna geçtiğini görün.
* **Prevention:** CI/CD pipeline'ında deploy öncesi imajın registry'de var olduğunu doğrulayan adımlar koyun.

---

### SCEN-12: Kubernetes Service Endpoint Empty (503 Service Unavailable)
* **Symptom:** Servis IP'sine veya Ingress adresine yapılan istekler `HTTP 503 Service Unavailable` veya `Connection Refused` döner.
* **Evidence:** `kubectl get endpoints <service_name>` çıktısında `<none>` görünür.
* **Diagnostic Commands:**
  ```bash
  kubectl get service <service_name> -o yaml
  kubectl get pods --show-labels
  kubectl get endpoints <service_name>
  ```
* **Root Cause:**
  - Service'in `spec.selector` etiketleri ile Pod'un `metadata.labels` etiketleri uyuşmamaktadır.
  - Pod'ların `readinessProbe` kontrolleri başarısız olduğu için Kubernetes trafiği kesmiştir.
* **Fix:** Selector etiketlerini Pod etiketleriyle eşitleyin veya failing readiness probe'u tamir edin.
* **Verification:** `kubectl get endpoints <service_name>` çıktısında Pod IP'lerinin listelendiğini doğrulayın.
* **Prevention:** Helm chart kullanarak Service selector ve Deployment label tanımlarını tek bir değişkenden (`_helpers.tpl`) üretin.

---

### SCEN-13: Kubernetes Pod OOMKilled (Exit Code 137)
* **Symptom:** Pod aniden yeniden başlar ve `kubectl describe pod` çıktısında `Last State: Terminated, Reason: OOMKilled, Exit Code: 137` görünür.
* **Evidence:** Konteyner, `resources.limits.memory` ile belirtilen bellek sınırını aşmıştır ve Linux OOM Killer tarafından `SIGKILL` (9) ile öldürülmüştür. (128 + 9 = 137).
* **Diagnostic Commands:**
  ```bash
  kubectl describe pod <pod_name> | grep -E "Reason:|Exit Code:|Limits:"
  kubectl top pod <pod_name>
  ```
* **Root Cause:** Uygulamada bellek sızıntısı (memory leak) vardır veya belirlenen memory limit uygulamanın normal yük altındaki ihtiyacından düşüktür.
* **Fix:**
  ```bash
  # Bellek limitini yükseltin:
  kubectl patch deployment <name> --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "512Mi"}]'
  ```
* **Verification:** Pod yeniden ayağa kalktıktan sonra `kubectl top pod` ile bellek tüketimini izleyin.
* **Prevention:** Uygulamalara yük testi yapıp p99 bellek tüketimine göre limitleri belirleyin; JVM uygulamalarında `-XX:MaxRAMPercentage` kullanın.

---

### SCEN-14: Argo CD OutOfSync / SyncFailed (Immutable Field Conflict)
* **Symptom:** Argo CD uygulamasında kırmızı `OutOfSync` veya `SyncFailed` uyarısı görünür; otomatik senkronizasyon başarısız olur.
* **Evidence:** Argo CD UI üzerinde `The Deployment "..." is invalid: spec.selector: Invalid value: field is immutable` hatası yazar.
* **Diagnostic Commands:**
  ```bash
  argocd app get <app_name>
  argocd app sync <app_name>
  ```
* **Root Cause:** Kubernetes'te `spec.selector` gibi değiştirilemez (immutable) alanlar canlı nesne üzerinde güncellenemez.
* **Fix:** Eski deployment'ı cluster'dan silin (`kubectl delete deployment ...`) ve Argo CD'ye tekrar `Sync` emri verin.
* **Verification:** Argo CD üzerinde uygulamanın yeşil `Synced & Healthy` olduğunu doğrulayın.
* **Prevention:** Immutable alanları değiştirmek gerektiğinde yeni bir Deployment adı ile geçiş yapın (Blue/Green).

---

### SCEN-15: Prometheus Target State DOWN
* **Symptom:** Prometheus Web UI (`/targets`) sayfasında uygulama hedefi kırmızı `DOWN` görünür; metrikler toplanmaz.
* **Evidence:** Error kolonunda `connection refused` veya `context deadline exceeded` yazar.
* **Diagnostic Commands:**
  ```bash
  curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, error: .lastError}'
  ```
* **Root Cause:**
  - Hedef uygulamanın `/metrics` endpointi açık değildir veya port yanlıştır.
  - Docker Compose / Kubernetes ağında DNS ismi yanlıştır (`localhost` yerine servis adı kullanılmalıdır).
* **Fix:** `prometheus.yml` dosyasındaki `targets: ['service-name:port']` ve `metrics_path` ayarlarını düzeltin.
* **Verification:** Prometheus targets sayfasında hedefin yeşil `UP` olduğunu doğrulayın.
* **Prevention:** Servisler için sağlık ve metrik standartlarını (Standard Observability Contract) zorunlu tutun.

---

### SCEN-16: Elasticsearch Memory Limit & `vm.max_map_count` Block
* **Symptom:** Elasticsearch konteyneri başlarken çöker ve loglarda `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]` yazar.
* **Evidence:** Linux çekirdeğinin varsayılan bellek haritalama sınırı mmapFS gereksinimini karşılamaz.
* **Diagnostic Commands:**
  ```bash
  sysctl vm.max_map_count
  docker logs elasticsearch
  ```
* **Root Cause:** İşletim sistemi çekirdek parametresi eksiktir.
* **Fix:**
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
  docker restart elasticsearch
  ```
* **Verification:** `curl http://localhost:9200` ile cluster durumunun yeşil/sarı olduğunu görün.
* **Prevention:** Host sunucu kurulumunda Ansible/Terraform bootstrap scripti ile kernel parametrelerini kalıcı olarak ayarlayın.

---

### SCEN-17: Kibana Data View Empty / Index Pattern Mismatch
* **Symptom:** Kibana Discover sekmesinde `No results match your search criteria` uyarısı çıkar, grafik boştur.
* **Evidence:** Elasticsearch içinde `devops-logs-2026.08.26` indeksi vardır ancak Kibana'da görünmez.
* **Diagnostic Commands:**
  ```bash
  curl http://localhost:9200/_cat/indices?v
  ```
* **Root Cause:**
  - Kibana'da tanımlanan Data View deseni (`app-logs-*`), Elasticsearch'teki gerçek indeks adı (`devops-logs-*`) ile uyuşmamaktadır.
  - Zaman filtresi (Time Picker) "Last 15 minutes" seçilidir ancak loglar farklı bir zaman damgasına sahiptir.
* **Fix:** Kibana Management -> Data Views menüsünden `devops-logs-*` deseni oluşturun ve Timestamp field olarak `@timestamp` seçin.
* **Verification:** Kibana Discover sekmesinde log satırlarının JSON alanlarıyla birlikte listelendiğini doğrulayın.
* **Prevention:** Log toplayıcılarında (Vector/FluentBit) indeks adlandırma kurallarını şirket genelinde standartlaştırın.
