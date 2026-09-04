terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Yerel test ve eğitim modu (LocalStack desteği)
  dynamic "endpoints" {
    for_each = var.enable_localstack ? [1] : []
    content {
      ec2 = var.localstack_endpoint
      sts = var.localstack_endpoint
    }
  }

  default_tags {
    tags = {
      Project     = "DevOps-Practitioner"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Lab         = "LAB-TF-08"
    }
  }
}
