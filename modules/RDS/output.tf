output "rds_endpoint" {
  value       = aws_db_instance.wordpress-db.endpoint
  description = "RDS Endpoint for the WordPress database"
}
output "rds_security_group_id" {
  value       = aws_security_group.rds_sg.id
  description = "ID of the RDS Security Group"
}
output "rds_secret_arn" {
  value       = aws_secretsmanager_secret.wordpress-secrets.arn
  description = "ARN of the Secrets Manager secret storing DB credentials"
}

output "wordpress_security_group_id" {
  value       = aws_security_group.wordpresssg.id
  description = "ID of the WordPress Security Group"

}

