provider "aws" {
  region  = var.aws_region
  profile = "terraform-admin"
}

# Use this for ACM validation in same region as ALB (ap-southeast-1).
# If you later add CloudFront, you’ll need us-east-1 for that separately.
