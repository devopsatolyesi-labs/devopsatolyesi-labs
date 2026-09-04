variable "aws_region" {
  type        = string
  description = "AWS hedef dağıtım bölgesi"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Ortam adı (dev, stage, prod)"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC ana IPv4 CIDR bloğu (RFC 1918)"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Yüksek erişilebilirlik için kullanılacak Kullanılabilirlik Alanları (AZ)"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blokları (DMZ & Ingress Katmanı)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDR blokları (İç Uygulama ve Veritabanı Katmanı)"
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "allowed_ssh_cidr" {
  type        = list(string)
  description = "Bastion hosta SSH erişimine izin verilecek IP aralığı"
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  type        = string
  description = "Doğrulama EC2 sunucuları için örnek tipi"
  default     = "t3.micro"
}

variable "enable_localstack" {
  type        = bool
  description = "AWS hesabı olmadan yerel LocalStack üzerinde çalıştırma bayrağı"
  default     = false
}

variable "localstack_endpoint" {
  type        = string
  description = "LocalStack API endpoint adresi"
  default     = "http://localhost:4566"
}
