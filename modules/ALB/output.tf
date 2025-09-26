output "alb_target_group_arn" {
  description = "Target Group ARN for the ALB"
  value       = [aws_lb_target_group.wordpress_tg.arn]
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.wordpress_alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.wordpress_alb.dns_name
}