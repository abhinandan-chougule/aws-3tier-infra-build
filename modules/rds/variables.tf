variable "project_name" {}
variable "vpc_id" {}
variable "private_db_subnet_ids" { type = list(string) }
variable "db_engine" {}
variable "db_engine_version" {}
variable "db_instance_class" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" { sensitive = true }
variable "app_security_group_id" {}
variable "tags" { type = map(string) }
