variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "ap-southeast-1"
}

variable "project_name" {
  type        = string
  description = "Name prefix for tagging and naming"
}

variable "domain_name" {
  type        = string
  description = "Root domain in Route 53 (e.g., example.com)"
}

variable "subdomain" {
  type        = string
  description = "App subdomain to point to ALB (e.g., api)"
  default     = "api"
}

variable "hosted_zone_id" {
  type        = string
  description = "Existing Route53 Hosted Zone ID for domain_name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR (e.g., 172.16.0.0/16)"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDRs"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "List of private app subnet CIDRs"
}

variable "private_db_subnet_cidrs" {
  type        = list(string)
  description = "List of private db subnet CIDRs"
}

variable "admin_cidr" {
  type        = string
  description = "Trusted CIDR for bastion SSH access (e.g., your office IP)"
}

variable "alb_certificate_domain" {
  type        = string
  description = "Domain to request ACM certificate for ALB (e.g., api.example.com)"
}

variable "sns_alert_email" {
  type        = string
  description = "Email for CloudWatch alarm notifications"
}

variable "artifact_bucket_name" {
  type        = string
  description = "S3 bucket holding application artifacts"
}

variable "artifact_object_key" {
  type        = string
  description = "Path to application JAR (e.g., releases/app.jar)"
}

variable "ec2_key_name" {
  type        = string
  description = "EC2 key pair name for bastion and app instances"
}

variable "app_instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "app_ami_id" {
  type        = string
  description = "AMI ID for app instances (Amazon Linux 2 or your hardened image)"
}

variable "asg_desired" {
  type        = number
  default     = 2
}

variable "asg_min" {
  type        = number
  default     = 2
}

variable "asg_max" {
  type        = number
  default     = 4
}

variable "db_engine" {
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  default     = "appdb"
}

variable "db_username" {
  type        = string
  default     = "appuser"
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket for Terraform state (optional)"
  default     = null
}

variable "tf_state_lock_table" {
  type        = string
  description = "DynamoDB table for state locking (optional)"
  default     = null
}
