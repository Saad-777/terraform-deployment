variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging AWS resources"
  type        = string
  default     = "multi-az-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "wordpress_db"

}

variable "db_password" {
  description = "The password for the database admin user"
  type        = string
  sensitive   = true

}

variable "db_username" {
  description = "The username for the database admin user"
  type        = string
  default     = "wp_user"

}

variable "key_pair_name" {
  description = "The keypair used to access the instances"
  type        = string
  default     = "sakn-kp"

}

