# ==============================================================================
# Dynamic Ubuntu 24.04 LTS AMI Lookup
# ==============================================================================
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical resmi sahibi
}

# ==============================================================================
# Automated Key Pair Generation (Turnkey Lab Erişimi)
# ==============================================================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab_key" {
  key_name   = "${var.environment}-lab-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/lab_key.pem"
  file_permission = "0400"
}

# ==============================================================================
# Bastion Host (Public Subnet 1 — Jump Server)
# ==============================================================================
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.lab_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.environment}-bastion-host"
    Role = "Bastion-Jump"
  }
}

# ==============================================================================
# Private Backend Workload (Private Subnet 1 — İzole Sunucu)
# ==============================================================================
resource "aws_instance" "private_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.private_app_sg.id]
  key_name                    = aws_key_pair.lab_key.key_name
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y curl net-tools
              # NAT Gateway çıkış IP'sini doğrulayan log kaydı
              OUTBOUND_IP=$(curl -s --connect-timeout 5 https://checkip.amazonaws.com || echo "UNKNOWN")
              echo "Private Instance Outbound NAT IP: $OUTBOUND_IP" > /var/log/nat-test.log
              # Basit test HTTP yanıtlayıcısı
              echo "HTTP/1.1 200 OK\r\nContent-Length: 38\r\n\r\nHello from Private Secure Subnet Backend" | nc -lk -p 8080 &
              EOF

  tags = {
    Name = "${var.environment}-private-app"
    Role = "Backend-Workload"
  }
}
