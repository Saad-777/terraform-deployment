variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string

}


variable "key_pair_name" {
  description = "Name of keyvalue-pair"
  type        = string

}

variable "wordpress_sg_id" {
  description = "Name of Wordpress-instance-security group"
  type        = string

}

variable "rds_host" {
  description = "DNS of RDS Host"
  type        = string

}

variable "secrets_arn" {
  description = "Arn of the secret in which DB credentials are present"
  type        = string

}

variable "aws_region" {
  description = "value of the region"
  type        = string

}

variable "target_group_arns" {
  description = "Target Group for ASG"
  type        = list(string)

}

variable "public_subnet_ids" {
  description = "Public subnets in which ASG will be deployed"
  type        = list(string)

}

