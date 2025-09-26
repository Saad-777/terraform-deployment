variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be placed"
  type        = list(string)
}

variable "wordpress_sg_id" {
  description = "Security Group ID for WordPress EC2 instances"
  type        = string
}

variable "project_name" {
  description = "Project name prefix for naming AWS resources"
  type        = string
  default     = "cloudformation-assignment"
}


