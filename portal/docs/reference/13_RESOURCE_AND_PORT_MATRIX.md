# 13 — KAYNAK, PROFİL VE PORT ÇAKIŞMA MATRİSİ (RESOURCE & PORT MATRIX)

Bu doküman, tek bir Ubuntu 24.04 LTS sunucusu üzerinde (8–16 GB RAM) bellek (RAM), işlemci (CPU) ve ağ portu (Port Collision) çakışması yaşamadan tüm labları yürütebilmesi için belirlenen **7 servis profili bütçelerini, geçiş kurallarını ve port haritasını** içerir.

---

## 1. 7 Servis Profili Bazlı Kaynak Bütçeleri (Resource Allocations)

| Profil Adı | İlgili Günler | İçerdiği Ana Servisler (2026 Pinned) | Tahmini RAM Bütçesi | Min. CPU İhtiyacı |
|---|---|---|---:|---:|
| `docker` | Gün 1, Gün 2 | Docker Engine 27.5.1, Python/Node.js/DB Konteynerleri, Trivy 0.74 | ~0.5 GB | 1 - 2 vCPU |
| `jenkins-ci` | Gün 3 | Jenkins 2.568.2 LTS (Java 17) | ~1.5 GB | 2 vCPU |
| `secure-ci` | Gün 3 | Jenkins 2.568.2 (~1.5GB) + SonarQube 26.8.0 (~1.5GB) + Harbor 2.15.2 (~0.8GB) | ~3.5 GB | 2 - 4 vCPU |
| `gitlab-ci` | Gün 3 | GitLab CE 17.9.3 (~3.5GB) + GitLab Runner 17.9.1 (~0.5GB) | ~4.5 GB | 2 - 4 vCPU |
| `kubernetes` | Gün 4, Gün 5 | kind 3-Node Cluster v1.31.9 (~2.5GB) + Argo CD 3.4.2 (~0.6GB) + Headlamp v0.45 (~0.2GB) | ~3.0 GB | 2 - 4 vCPU |
| `monitoring` | Gün 5 | Prometheus 3.13.2 LTS (~0.6GB) + Grafana 13.1.5 (~0.4GB) + Alertmanager v0.33 (~0.2GB) | ~1.2 GB | 1 - 2 vCPU |
| `logging` | Gün 5 | Elasticsearch 8.17.8 (~1.5GB) + Kibana 8.17.8 (~0.8GB) + Vector 0.40.2 (~0.1GB) | ~2.4 GB | 2 - 4 vCPU |

---

## 2. Host Port Haritası ve Çakışma Önleme Matrisi

Aşağıdaki tabloda eğitim boyunca kullanılan tüm servislerin host üzerindeki portları listelenmiştir. Çakışan servisler aynı profile konulmamış veya farklı portlara yönlendirilmiştir.

| Host Portu | Servis Adı | Teknoloji & Sürüm | Dahil Olduğu Profil | Çakışma Riski & Önlem |
|---|---|---|---|---|
| **22** | SSH Server | Linux Host | Global | Asla değiştirilmez; daima açık kalır. |
| **80 / 443** | Ingress Controller | kind / K8s v1.31.9 | `kubernetes` | Hostta Apache/Nginx çalışıyorsa durdurulmalıdır. |
| **3000** | Grafana Web UI / Node App | Grafana 13.1.5 / Node 20 | `monitoring` / `docker` | Gün 2 Node App `3000` kullanır, Gün 5 Grafana `3000` kullanır (Farklı profiller). |
| **5000** | Local Docker Registry | Docker Registry v2 | `docker` | Basit yerel OCI imaj push hedefi. |
| **5432** | PostgreSQL Database | PostgreSQL 16.4 | `docker` | Hostta yerel postgres servisi varsa durdurulmalıdır. |
| **5601** | Kibana Web UI | Kibana 8.17.8 | `logging` | Benzersiz port, çakışma yok. |
| **6379** | Redis Cache | Redis 7.4-alpine | `docker` | Dahili bridge ağında tutulur. |
| **8000** | Python FastAPI / Order API | FastAPI / Uvicorn | `docker` / `monitoring` | Demo web servisleri için standart uygulama portu. |
| **8080** | Jenkins Controller / Demo Web | Jenkins 2.568.2 LTS | `jenkins-ci` / `secure-ci` / `docker` | Gün 1'de Nginx 8080 kullanır; Gün 3'te Jenkins 8080'i devralır. |
| **8081** | GitLab Web UI | GitLab CE 17.9.3 | `gitlab-ci` | Jenkins ile çakışmaması için GitLab 8081 portuna haritalanır. |
| **8082** | Harbor Registry Portal | Harbor v2.15.2 | `secure-ci` | Standart 80 portu yerine 8082'ye haritalanır. |
| **8085** | Argo CD Web UI & API | Argo CD v3.4.2 | `kubernetes` | Standart 443 yerine port-forward ile 8085'e yönlendirilir. |
| **8088** | Headlamp Web UI | Headlamp v0.45.0 | `kubernetes` | 8088:4466 haritalamasıyla Kubernetes dashboard sağlar. |
| **8090** | Terraform Web Server | Docker Provider | `docker` | Terraform testleri için ayrılmış port. |
| **9000** | SonarQube Server | SonarQube 26.8.0 Community | `secure-ci` | Benzersiz port, çakışma yok. |
| **9090** | Prometheus Server | Prometheus 3.13.2 LTS | `monitoring` | Benzersiz port, çakışma yok. |
| **9093** | Alertmanager Web UI | Alertmanager v0.33.0 | `monitoring` | Benzersiz port, çakışma yok. |
| **9100** | Node Exporter | Node Exporter | `monitoring` | Host metrik toplayıcısı. |
| **9200** | Elasticsearch REST API | Elasticsearch 8.17.8 | `logging` | `ES_JAVA_OPTS=-Xms1g -Xmx1g` ile sabitlenir. |

---

## 3. Profil Geçiş ve Bellek Yönetim Talimatı (Profile Switching Rules)

1. **Profil Başlatma ve Durdurma:**
   ```bash
   # İstenen profili başlat
   bash outputs/lab-assets/LAB-ENV-00/scripts/start-profile.sh <profil-adı>

   # Profili durdur ve RAM'i boşalt
   bash outputs/lab-assets/LAB-ENV-00/scripts/stop-profile.sh <profil-adı>

   # Tüm profilleri kapat
   bash outputs/lab-assets/LAB-ENV-00/scripts/stop-profile.sh all
   ```
2. **Elasticsearch & SonarQube JVM Kısıtları:**
   Belleğin kontrolsüz büyümesini önlemek için:
   - SonarQube: `SONAR_JAVA_OPTS=-Xms512m -Xmx512m`
   - Elasticsearch 8.17: `ES_JAVA_OPTS=-Xms1g -Xmx1g`
3. **Sistem Sağlık ve Port Denetimi:**
   ```bash
   bash outputs/lab-assets/LAB-ENV-00/scripts/status.sh
   bash outputs/lab-assets/LAB-ENV-00/scripts/validate-environment.sh
   ```
