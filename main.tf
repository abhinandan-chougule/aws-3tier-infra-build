locals {
  tags = {
    Project = var.project_name
    Owner   = "platform"
    Managed = "terraform"
  }
}

module "vpc" {
  source                   = "./modules/vpc"
  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  admin_cidr               = var.admin_cidr
  tags                     = local.tags
}

module "s3_artifacts" {
  source      = "./modules/s3-artifacts"
  bucket_name = var.artifact_bucket_name
  tags        = local.tags
}

module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_certificate_arn = module.route53.acm_certificate_arn
  target_port         = 8080
  tags                = local.tags
}

module "app_asg" {
  source                = "./modules/app-asg"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_app_subnet_ids
  app_ami_id            = var.app_ami_id
  instance_type         = var.app_instance_type
  ec2_key_name          = var.ec2_key_name
  target_group_arn      = module.alb.target_group_arn
  artifact_bucket_name  = module.s3_artifacts.bucket_name
  artifact_object_key   = var.artifact_object_key
  db_security_group_id  = module.rds.db_security_group_id
  app_security_group_id = module.vpc.app_sg_id
  alb_security_group_id = module.vpc.alb_sg_id
  desired_capacity      = var.asg_desired
  min_size              = var.asg_min
  max_size              = var.asg_max
  tags                  = local.tags
}

module "bastion" {
  source           = "./modules/bastion"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  ec2_key_name     = var.ec2_key_name
  admin_cidr       = var.admin_cidr
  tags             = local.tags
}

module "rds" {
  source                = "./modules/rds"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  db_engine             = var.db_engine
  db_engine_version     = var.db_engine_version
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  app_security_group_id = module.vpc.app_sg_id
  tags                  = local.tags
}

module "route53" {
  source             = "./modules/route53"
  hosted_zone_id     = var.hosted_zone_id
  domain_name        = var.domain_name
  subdomain          = var.subdomain
  alb_dns_name       = module.alb.alb_dns_name
  vpc_id             = module.vpc.vpc_id
  certificate_domain = var.alb_certificate_domain
  tags               = local.tags
}

module "monitoring" {
  source           = "./modules/monitoring"
  project_name     = var.project_name
  sns_alert_email  = var.sns_alert_email
  target_group_arn = module.alb.target_group_arn
  tags             = local.tags
}
