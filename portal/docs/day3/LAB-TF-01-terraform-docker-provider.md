# LAB-TF-01 — Terraform Fundamentals: Docker Provider & State Lifecycle

| 🎯 Seviye | ⏱️ Tahmini Süre | 🛠️ Profil / Araçlar | 🔌 Açık Portlar |
| :--- | :--- | :--- | :--- |
| 🟢 **CORE** (Temel Seviye) | ⏱️ 45 dakika | `docker` | `8090` |

> [!TIP]
> 📥 **Başlangıç Paketi:** [Bu labın başlangıç paketini indir (LAB-TF-01.zip)](/downloads/LAB-TF-01.zip) — paket README ve başlangıç kodlarını içerir; çözüm içermez.
> 
> **Terminalde çalışma ortamını hazırlayın:**
> ```bash
> mkdir -p ~/labs/LAB-TF-01
> cd ~/labs/LAB-TF-01
> ```


## 1. Lab Senaryosu
Altyapı kaynaklarının yönetim panellerinden manuel olarak tıklanarak oluşturulması, ortamlar arasında konfigürasyon sapmalarına (drift), denetlenemeyen değişikliklere ve tekrarlanamayan sistemlere yol açar. Altyapı Kod Olarak (Infrastructure as Code - IaC) yaklaşımı, sunucu, ağ ve konteyner kaynaklarının deklaratif metin dosyalarında tanımlanmasını ve versiyonlanmasını sağlar. Bu çalışmada HashiCorp Terraform ve Docker Provider kullanılarak ağ, imaj ve konteyner kaynakları kod olarak tanımlanır; `plan` ve `apply` yaşam döngüsü, state mekanizması ve dışarıdan yapılan bir müdahalede oluşan drift durumu incelenir.

## 2. Amaç
Terraform temel iş akışını (`init`, `fmt`, `validate`, `plan`, `apply`, `destroy`) uygulamak, `kreuzwerker/docker` sağlayıcısı ile deklaratif altyapı oluşturmak, `terraform.tfstate` dosyasının rolünü ve durum kaymasını (state drift) tespit edip onarmak.

## 3. Mimari / Akış
```text
  [ Terraform Manifestoları (*.tf) ]
                 |
        (terraform apply)
                 |
                 +---> Docker Network: "tf_bridge_net"
                 +---> Docker Image:   "nginx:1.27-alpine"
                 +---> Docker Container: "tf-managed-web-server" (Port 8090:80)
                 |
                 v
  [ State Dosyası: terraform.tfstate ] <--- (Tek Doğruluk Kaynağı)
```

## 4. Ön Koşullar
- Terraform CLI (v1.6+) kurulu olmalıdır (`terraform version`)
- Docker Engine çalışır durumda olmalıdır
- Host üzerinde 8090 portu boş olmalıdır
- Önceden tamamlanması önerilen lab: `LAB-DOC-01`

Aşağıdaki komutlarla başlangıç durumunu kontrol edin:
```bash
terraform version
docker ps
mkdir -p ~/labs/LAB-TF-01
cd ~/labs/LAB-TF-01
```

## 5. Adım Adım Uygulama

### Adım 1 — Terraform Yapılandırma Dosyalarını Oluşturma
Sağlayıcı, değişken ve çıktı tanımlarını içeren dosyaları hazırlayın:
```hcl
cat <<'EOF' > main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "custom_network" {
  name = var.network_name
}

resource "docker_image" "nginx_image" {
  name         = "nginx:1.27-alpine"
  keep_locally = false
}

resource "docker_container" "nginx_web" {
  image = docker_image.nginx_image.image_id
  name  = var.container_name

  ports {
    internal = 80
    external = var.external_port
  }

  networks_advanced {
    name = docker_network.custom_network.name
  }

  env = [
    "APP_ENV=${var.environment}"
  ]
}
EOF

cat <<'EOF' > variables.tf
variable "container_name" {
  type        = string
  description = "Name of the Docker container"
  default     = "tf-managed-web-server"
}

variable "external_port" {
  type        = number
  description = "Host port exposed for HTTP"
  default     = 8090
}

variable "network_name" {
  type        = string
  description = "Custom bridge network name"
  default     = "tf_bridge_net"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}
EOF

cat <<'EOF' > outputs.tf
output "container_id" {
  value       = docker_container.nginx_web.id
  description = "Docker Container ID"
}

output "web_url" {
  value       = "http://localhost:${var.external_port}"
  description = "Access URL for the deployed web application"
}

output "network_id" {
  value       = docker_network.custom_network.id
  description = "Created Bridge Network ID"
}
EOF
```

### Adım 2 — Terraform Yaşam Döngüsü Adımlarını Çalıştırma
Sağlayıcı eklentilerini indirin, sözdizimini kontrol edin ve plan oluşturun:
```bash
# Sağlayıcıyı başlat
terraform init

# Formatlama ve sözdizimi doğrulaması
terraform fmt -check
terraform validate

# Altyapı planını incele ve kaydet
terraform plan -out=tfplan

# Altyapıyı uygula
terraform apply tfplan
```

### Adım 3 — Oluşturulan Kaynakları ve State Dosyasını Denetleme
Çıktı değerlerini okuyun ve HTTP erişimini test edin:
```bash
terraform output web_url
curl -I $(terraform output -raw web_url)
terraform state list
```

## 6. Beklenen Sonuç
Adım 2'deki `terraform apply` çıktısı:
```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:
container_id = "..."
network_id = "..."
web_url = "http://localhost:8090"
```

Adım 3'teki state listesi çıktısı:
```text
docker_container.nginx_web
docker_image.nginx_image
docker_network.custom_network
```


---

## 🛠️ En Çok Kullanılan Terraform Komutları ve State Yönetimi (Cheat Sheet)

Altyapıyı kod olarak (IaC) yönetirken production ortamlarında en sık başvurulan Terraform komutları:

### 1. Temel Yaşam Döngüsü ve Doğrulama
```bash
# Sağlayıcı eklentilerini (providers) indirme ve modülleri başlatma
terraform init -upgrade

# HCL sözdizimi ve mantıksal değişken geçerliliğini denetleme
terraform validate

# Tüm dizindeki .tf dosyalarını kanonik standartta biçimlendirme
terraform fmt -recursive

# Değişiklikleri planlama ve çıktı dosyasını kilitleme (CI/CD standardı)
terraform plan -out=tfplan

# Planlanan değişiklikleri onay beklemeden güvenle uygulama
terraform apply tfplan

# Yönetilen tüm altyapıyı güvenli şekilde yok etme
terraform destroy -auto-approve
```

### 2. State (Durum Dosyası) Yönetimi
```bash
# State dosyasındaki tüm yönetilen kaynakları listeleme
terraform state list

# Belirli bir kaynağın (ör. docker_container.web) tüm detaylı özniteliklerini görme
terraform state show docker_container.web

# Bir kaynağın adını state içinde bozmadan yeniden adlandırma (Refactor)
terraform state mv docker_container.old_name docker_container.new_name

# Bir kaynağı altyapıdan silmeden sadece Terraform yönetiminden çıkarma
terraform state rm docker_container.legacy_app
```

### 3. Hedefe Yönelik Operasyonlar ve İçe Aktarma (Target & Import)
```bash
# Yalnızca belirli bir kaynağı veya modülü derleme/uygulama
terraform apply -target=docker_container.database

# Gerçek altyapı durumunu okuyup state dosyasıyla senkronize etme
terraform refresh

# Manuel oluşturulmuş mevcut bir kaynağı Terraform yönetimine dahil etme
terraform import docker_image.nginx nginx:latest
```

---

## 🧠 İnteraktif Alıştırmalar ve Senaryo Soruları

??? question "Soru 1: CI/CD boru hatlarında neden `terraform apply` komutu doğrudan çalıştırılmaz da `terraform plan -out=tfplan` ve ardından `terraform apply tfplan` şeklinde iki aşamalı çalıştırılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `terraform plan -out=tfplan` komutu, planlama anındaki tam altyapı durumunu ve yapılacak değişiklikleri bir ikili dosyaya (plan file) kilitler. `terraform apply tfplan` çalıştırıldığında Terraform tekrar gerçek dünyaya bakmaz, kilitlenen dosyadaki onaylanmış değişiklikleri birebir uygular. Bu durum, planlama ile onaylama arasında başka birinin veya sürecin altyapıyı değiştirmesinden kaynaklanabilecek sürpriz yıkımları (Race Condition / Concurrency Issues) önler.

??? question "Soru 2: `terraform.tfstate` dosyasının Git deposuna commit edilmesi neden çok tehlikeli bir güvenlik açığıdır ve nasıl engellenir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `terraform.tfstate` dosyası, altyapıda tanımlanan tüm veritabanı şifrelerini, API anahtarlarını, TLS private key'lerini ve ortam değişkenlerini **düz metin (plaintext)** olarak saklar. Git'e commit edilirse tüm gizli sırlar açık kaynak repoda ifşa olur. Bu durum `.gitignore` dosyasına `*.tfstate*` eklenerek ve state dosyasını şifrelenmiş uzak depolama alanlarında (AWS S3 + DynamoDB State Locking, Terraform Cloud, GitLab Managed State veya GCP GCS) saklayarak çözülür.

??? question "Soru 3: Altyapıda manuel olarak değiştirilen bir kaynağı (Drift) tespit edip Terraform konfigürasyonuna geri senkronize etmek için ne yapılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `terraform plan` komutu çalıştırıldığında Terraform otomatik olarak sağlayıcı API'sini sorgulayarak gerçek durumu okur ve state dosyası ile `.tf` kodları arasındaki sapmayı (Configuration Drift) gösterir. State dosyasını en güncel gerçek dünya verisiyle güncellemek için `terraform refresh` veya `terraform apply -refresh-only` komutu kullanılır.

??? question "Soru 4: `terraform destroy` çalıştırıldığında belirli kritik bir kaynağın (örneğin production veritabanı) yanlışlıkla silinmesini engellemek için kod içinde hangi blok kullanılır?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `lifecycle` bloğu altındaki `prevent_destroy` kuralı kullanılır:
        ```hcl
        resource "docker_container" "db" {
          name  = "production-db"
          image = "postgres:16"

          lifecycle {
            prevent_destroy = true
          }
        }
        ```
        Bu kural tanımlandığında, `terraform destroy` komutu çalıştırılsa bile Terraform hata vererek işlemi durdurur.

??? question "Soru 5: `terraform fmt` komutunun CI/CD doğrulama adımında geliştiricilerin kod standartlarına uyup uymadığını kontrol etmek için hangi bayrakla çalıştırılması önerilir?"
    ??? tip "💡 Çözümü Göster"
        **Cevap:**
        `terraform fmt -check` bayrağı ile çalıştırılır. Dosyaları otomatik düzenlemek yerine, formatlanmamış bir dosya bulursa exit code `1` döner ve CI boru hattını durdurarak geliştiriciyi dosyalarını biçimlendirmeye zorlar.


## 8. Sorun Giderme

### Belirti
Terraform dışında manuel olarak konteyner silindiğinde (`docker rm -f tf-managed-web-server`) sistem durumu kayar (State Drift).

### Kanıt
`docker ps` çıktısında konteyner görülmezken `terraform state list` içinde kayıt mevcuttur.

### Kontrol Komutu
```bash
terraform plan
```

### Muhtemel Neden
Altyapıya kod dışından (out-of-band) manuel müdahale yapılmıştır.

### Çözüm
Terraform'un gerçek dünya durumunu algılayıp eksik kaynağı yeniden üretmesi için `apply` komutunu çalıştırın:
```bash
terraform apply -auto-approve
```

### Tekrar Doğrulama
```bash
docker ps --filter "name=tf-managed-web-server"
# Konteyner yeniden Up durumunda listelenmelidir.
```

## 10. Production Notu
Üretim ortamlarında `terraform.tfstate` dosyası asla yerel diskte veya Git reposunda saklanmaz; AWS S3, Google Cloud Storage (GCS) veya Terraform Cloud gibi uzak depolama (remote backend) üzerinde tutulur ve eşzamanlı değişiklikleri engellemek için state locking mekanizması (DynamoDB / GCS object lock) aktif edilir.

## 11. Challenge
`main.tf` içine bir `resource "docker_volume" "web_data"` tanımı ekleyerek Nginx'in `/usr/share/nginx/html` dizinini kalıcı bir volume ile ilişkilendirin.
