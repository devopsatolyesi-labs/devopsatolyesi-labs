# ==============================================================================
# Internet Gateway (IGW) - Kuzey-Güney Dış İnternet Bağlantısı
# ==============================================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-internet-gateway"
  }
}

# ==============================================================================
# Elastic IP (EIP) for NAT Gateway
# ==============================================================================
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.environment}-nat-gw-eip"
  }
}

# ==============================================================================
# NAT Gateway (Private Subnet'lerin İnternete Güvenli Çıkışı)
# ==============================================================================
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Public Subnet 1 içinde konuşlanır
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.environment}-nat-gateway"
  }
}
