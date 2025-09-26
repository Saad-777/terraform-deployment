output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "web_security_group_id" {
  value = aws_security_group.HTTP.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.wordpressRDS.name
}
