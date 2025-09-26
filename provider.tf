terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # (Optional) Use Terraform Cloud or S3 backend
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "network/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region
}
