variable "project_name" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "app_ami_id" {}
variable "instance_type" {}
variable "ec2_key_name" {}
variable "target_group_arn" {}
variable "artifact_bucket_name" {}
variable "artifact_object_key" {}
variable "db_security_group_id" {}
variable "app_security_group_id" {}
variable "alb_security_group_id" {}
variable "desired_capacity" { type = number }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "tags" { type = map(string) }
