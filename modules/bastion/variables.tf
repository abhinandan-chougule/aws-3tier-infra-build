variable "project_name" {}
variable "vpc_id" {}
variable "public_subnet_id" {}
variable "ec2_key_name" {}
variable "admin_cidr" {}
variable "tags" { type = map(string) }
