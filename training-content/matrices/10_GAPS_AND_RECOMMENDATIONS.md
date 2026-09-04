# 10 — BOŞLUK ANALİZİ VE MİMARİ TAVSİYELER (GAPS & RECOMMENDATIONS)

Bu doküman; müfredat tasarımı, öğrenci ortamı kısıtları, araç seçimleri ve pedagojik riskler üzerine yapılan derinlemesine analizleri (Gap Analysis) ve eğitmen/platform ekibi için stratejik tavsiyeleri içerir.

---

## 1. Tespit Edilen Boşluklar ve Riskler (Gaps & Technical Risks)

### 1.1. Tek Sunucu Bellek Kısıtı (Single Ubuntu RAM Constraint)
* **Boşluk / Risk:** Öğrenci sunucusunda (özellikle 8 GB RAM'e sahip ortamlarda) GitLab CE (4 GB), Jenkins (1.5 GB), SonarQube (2 GB), Elasticsearch (2 GB) ve kind Kubernetes (3 GB) aynı anda çalıştırılmaya kalkarsa Linux OOM Killer devreye girer ve sistem kilitlenir.
* **Uygulanan Çözüm (Mitigation):** Katı **Profil İzolasyonu (Profile Separation)** uygulanmıştır. Öğrenci her gün sadece o günün profillerini (`docker`, `secure-ci`, `gitlab-ci`, `kubernetes`, `monitoring`, `logging`) çalıştırır. Final capstone'da aşamalı (phased) geçiş modeli kurgulanmıştır.

### 1.2. Bulut Altyapısı (AWS/GCP) vs Yerel Terraform (Local IaC)
* **Boşluk / Risk:** AWS hesabı veya GCP kredisi gerektiren eğitimlerde faturalandırma ve öğrenci IAM hataları süreyi tüketir.
* **Uygulanan Çözüm:** Terraform öğretimi için AWS yerine yerel `kreuzwerker/docker`, `hashicorp/kubernetes` ve `hashicorp/helm` sağlayıcıları kullanılmıştır. Böylece öğrenciler sıfır maliyetle gerçek deklaratif IaC döngüsünü (`init`, `plan`, `apply`, `state drift`) öğrenir. AWS 101 ise eğitmen tarafından kavramsal/console gösterimi olarak tutulmuştur.

### 1.3. Jenkins vs GitLab CI Karşılaştırması ve Zaman Yönetimi
* **Boşluk / Risk:** Hem Jenkins hem GitLab CI'ın derinlemesine 1 güne sığdırılması zordur.
* **Uygulanan Çözüm:** Gün 3 sabahı Jenkins Declarative Pipeline (kurumsal eski/popüler standart), öğleden sonra ise modern GitLab CI/CD (modern SaaS standardı) mantığı karşılaştırmalı olarak işlenir. Öğrenci her iki mental modeli de kavrar.

### 1.4. Ingress ve Yük Dengeleyici (LoadBalancer) Kısıtları
* **Boşluk / Risk:** `kind` ortamında bulut LoadBalancer (AWS ALB / GCP Cloud Load Balancing) bulunmaz.
* **Uygulanan Çözüm:** `kind-config.yaml` içine `extraPortMappings` (80 ve 443) eklenmiş ve NGINX Ingress Controller kind uyumlu yamalanmıştır. Öğrenciler localhost üzerinden Ingress deneyimini birebir yaşar.

### 1.5. Ağır Mikroservis Yığınları (OpenTelemetry & Online Boutique)
* **Boşluk / Risk:** Google Online Boutique (11 servis) ve OTel Astronomy Shop öğrenci VM'ini aşırı zorlar.
* **Uygulanan Çözüm:** Öğrenci lablarında hafif `devops-demo-python` ve `devops-demo-node` kullanılır; ağır stackler eğitmen tarafından `devopsatolyesi.com` reference sistemlerinde canlı olarak gösterilir (SEE IT modeli).

---

## 2. Stratejik Tavsiyeler (Recommendations)

### 2.1. Eğitmen İçin Tavsiyeler (For Instructors)
1. **SEE IT ile Başlayın:** Her lab öncesinde `devopsatolyesi.com` üzerindeki çalışan sistemi (örn: canlı Argo CD veya Grafana paneli) 2 dakika gösterin; öğrencinin nereye varmaya çalıştığını görmesini sağlayın.
2. **Sınıf Hızına Göre Dinamik Yönetim:** Sınıf yavaşsa `Slow-Class Shortcut` adımlarını uygulayın; hızlı bitiren 1-2 ileri öğrenciye hemen `CHALLENGE` lablarını yönlendirin.
3. **Break/Fix'i Asla Atlamayın:** DevOps mühendisi sadece "çalışan sistemi kuran" değil, "bozuk sistemi düzelten" kişidir. Arıza simülasyonları eğitimin en yüksek değer üreten kısmıdır.

### 2.2. Platform & Codex Ekibi İçin Tavsiyeler (For Platform / Codex)
1. **Otomatik Preflight Scripti:** Öğrenci sunucusuna giriş yaptığında RAM, Docker ve kind durumunu kontrol eden bir hoş geldin banner'ı ekleyin.
2. **Profile Geçiş Scriptleri:** `switch-profile secure-ci` veya `switch-profile kubernetes` gibi tek satırlık profil temizleme/yükleme helper scriptleri oluşturun.
3. **Deterministik Port Yönetimi:** Her profilin host portlarını `outputs/13_RESOURCE_AND_PORT_MATRIX.md` tablosuna göre kilitleyin.
