output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "List of private subnet IDs"
}

output "nat_gateway_id" {
  value       = module.vpc.nat_gateway_id
  description = "ID of the single NAT Gateway"
}

output "web_security_group_id" {
  value       = module.vpc.web_security_group_id
  description = "ID of the Web Security Group"
}


