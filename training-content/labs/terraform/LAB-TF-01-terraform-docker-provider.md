# LAB-TF-01 — Terraform Fundamentals: Docker Provider & State Lifecycle

## Metadata
- **Seviye:** CORE
- **Önerilen Gün:** Gün 3
- **Tahmini Süre:** 45 dk
- **Gerekli Profil:** `docker`
- **Host Portları:** `8090:80`
- **Çalışma Dizini:** `~/labs/LAB-TF-01`

---

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

## 7. Doğrulama
Oluşturulan web servisinin HTTP 200 döndürdüğünü doğrulayın:
```bash
WEB_URL=$(terraform output -raw web_url)
if curl -sf "$WEB_URL" | grep -q "Welcome to nginx"; then
  echo "VALIDATION SUCCESS: Terraform successfully provisioned container, network and exposed on $WEB_URL."
else
  echo "VALIDATION FAILED: Unable to reach $WEB_URL." && exit 1
fi
```

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

## 9. Temizlik / Sıfırlama
Terraform tarafından yönetilen tüm kaynakları yok edin ve çalışma dizinini temizleyin:
```bash
terraform destroy -auto-approve
rm -rf .terraform .terraform.lock.hcl terraform.tfstate* tfplan
rm -rf ~/labs/LAB-TF-01
```

## 10. Production Notu
Üretim ortamlarında `terraform.tfstate` dosyası asla yerel diskte veya Git reposunda saklanmaz; AWS S3, Google Cloud Storage (GCS) veya Terraform Cloud gibi uzak depolama (remote backend) üzerinde tutulur ve eşzamanlı değişiklikleri engellemek için state locking mekanizması (DynamoDB / GCS object lock) aktif edilir.

## 11. Challenge
`main.tf` içine bir `resource "docker_volume" "web_data"` tanımı ekleyerek Nginx'in `/usr/share/nginx/html` dizinini kalıcı bir volume ile ilişkilendirin.
