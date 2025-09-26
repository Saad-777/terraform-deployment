variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
