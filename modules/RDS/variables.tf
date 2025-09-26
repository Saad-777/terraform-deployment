variable "vpc_id" {
  description = "The ID of the VPC where the RDS instance will be deployed"
  type        = string
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

variable "project_name" {
  description = "Project name for tagging AWS resources"
  type        = string

}

variable "db_subnet_group_name" {
  description = "The name of the DB subnet group to use for the RDS instance"
  type        = string

}