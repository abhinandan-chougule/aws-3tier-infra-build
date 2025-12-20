variable "project_name" {}
variable "vpc_id" {}
variable "public_subnet_id" {}
variable "ec2_key_name" {}
variable "admin_cidr" {}
variable "tags" { type = map(string) }
variable "enable_public_ip" {
  description = "Whether to assign a public IP to the bastion host"
  type        = bool
  default     = false
}

// Optional: canonical owner ID for AMI lookup. Keep blank and set locally in a
// non-checked-in `terraform.tfvars` (recommended) to avoid exposing account IDs
// in the repo. If left empty, falls back to using the "amazon" owner alias.
variable "ami_owner_id" {
  description = "Optional AMI owner account id (e.g. Ubuntu publisher id)"
  type        = string
  default     = ""
}
