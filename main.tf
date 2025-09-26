module "vpc" {
  source       = "./modules/Vpc"
  region       = var.region
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}



module "wordpressRDS" {
  source = "./modules/RDS"

  # Pass in project and environment info
  project_name = var.project_name

  # VPC related
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name

  # DB details
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "wordpressASG" {
  source = "./modules/ASG"

  project_name      = var.project_name
  rds_host          = module.wordpressRDS.rds_endpoint
  key_pair_name     = var.key_pair_name
  aws_region        = var.region
  wordpress_sg_id   = module.wordpressRDS.wordpress_security_group_id
  secrets_arn       = module.wordpressRDS.rds_secret_arn
  target_group_arns = module.ALB.alb_target_group_arn
  public_subnet_ids = module.vpc.public_subnet_ids

}

module "ALB" {
  source = "./modules/ALB"

  project_name      = var.project_name
  wordpress_sg_id   = module.wordpressRDS.wordpress_security_group_id
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

}