output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ALB DNS name"
}

output "app_url" {
  value       = "https://${var.subdomain}.${var.domain_name}"
  description = "Public URL for the application"
}

output "bastion_public_ip" {
  value       = module.bastion.public_ip
  description = "Bastion host public IP"
}

output "rds_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS endpoint"
}

output "artifact_bucket" {
  value       = module.s3_artifacts.bucket_name
  description = "Artifact S3 bucket name"
}

