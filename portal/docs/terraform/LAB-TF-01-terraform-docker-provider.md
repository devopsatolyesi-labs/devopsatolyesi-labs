# LAB-TF-01 — Terraform Fundamentals: Docker Provider & State Lifecycle

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Temel | 45 dakika | `docker` | `8090` |

[LAB-TF-01.zip](/downloads/LAB-TF-01.zip)


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

## Doğal Doğrulama ve Beklenen Sonuç
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

## Doğal Doğrulama ve Beklenen Sonuç
Oluşturulan web servisinin HTTP 200 döndürdüğünü doğrulayın:
```bash
WEB_URL=$(terraform output -raw web_url)
if curl -sf "$WEB_URL" | grep -q "Welcome to nginx"; then
  echo "VALIDATION SUCCESS: Terraform successfully provisioned container, network and exposed on $WEB_URL."
else
  echo "VALIDATION FAILED: Unable to reach $WEB_URL." && exit 1
fi
```
