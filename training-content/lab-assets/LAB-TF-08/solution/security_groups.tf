# ==============================================================================
# Bastion Host Security Group (Jump Server İzinleri)
# ==============================================================================
resource "aws_security_group" "bastion_sg" {
  name        = "${var.environment}-bastion-sg"
  description = "Security group for public Bastion jump host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH administrative access from authorized CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-bastion-sg"
  }
}

# ==============================================================================
# Internal Application Security Group (Zero Trust İzolasyon)
# ==============================================================================
resource "aws_security_group" "private_app_sg" {
  name        = "${var.environment}-private-app-sg"
  description = "Security group for private backend app and database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH jump access strictly from Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description     = "App HTTP traffic from Bastion / Web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Outbound internet via NAT Gateway (updates, package pulls)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-private-app-sg"
  }
}
