variable "project_name" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" { type = list(string) }
variable "private_app_subnet_cidrs" { type = list(string) }
variable "private_db_subnet_cidrs" { type = list(string) }
variable "admin_cidr" { type = string }
variable "tags" { type = map(string) }
