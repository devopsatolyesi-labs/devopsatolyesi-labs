output "vpc_id" {
  description = "Oluşturulan AWS VPC'nin benzersiz ID'si"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet ID listesi"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet ID listesi"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "VPC'ye bağlı Internet Gateway ID'si"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway'e tahsis edilen sabit Elastic IP (EIP)"
  value       = aws_eip.nat.public_ip
}

output "bastion_public_ip" {
  description = "Bastion Jump Host'un genel erişilebilir IPv4 adresi"
  value       = aws_instance.bastion.public_ip
}

output "private_app_ip" {
  description = "Private Subnet içindeki backend sunucusunun yerel IP adresi"
  value       = aws_instance.private_app.private_ip
}

output "ssh_bastion_command" {
  description = "Bastion sunucusuna doğrudan SSH bağlantı komutu"
  value       = "ssh -i lab_key.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "ssh_jump_command" {
  description = "Bastion üzerinden Private sunucuya tünelli (ProxyJump) bağlantı komutu"
  value       = "ssh -i lab_key.pem -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.private_app.private_ip}"
}
