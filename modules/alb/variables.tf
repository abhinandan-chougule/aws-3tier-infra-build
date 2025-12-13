variable "project_name" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "alb_certificate_arn" { type = string }
variable "target_port" { type = number }
variable "tags" { type = map(string) }
