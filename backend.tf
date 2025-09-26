terraform {
  backend "s3" {
    bucket         = "4899-9409terraformassignmentbucket"
    key            = "terraform.tfstate" # <--- directly in bucket root
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
