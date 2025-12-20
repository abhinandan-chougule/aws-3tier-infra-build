# ===== Get latest Ubuntu AMI =====
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (official Ubuntu publisher)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ===== Bastion IAM Role for SSM =====
resource "aws_iam_role" "bastion_ssm" {
  name_prefix = "${var.project_name}-bastion-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.project_name}-bastion-role" })
}

# ===== Attach SSM Core Policy =====
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.bastion_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ===== Instance Profile =====
resource "aws_iam_instance_profile" "bastion_profile" {
  name_prefix = "${var.project_name}-bastion-"
  role        = aws_iam_role.bastion_ssm.name
}

# ===== Bastion Security Group =====
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-bastion-sg-"
  description = "Allow SSH from admin CIDR"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-bastion-sg" })
}

# ===== Bastion EC2 Instance =====
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name

  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y mysql-client ec2-instance-connect

              mysql --version

              # Ensure SSH service is running
              systemctl enable ssh
              systemctl restart ssh
              EOF

  tags = merge(var.tags, { Name = "${var.project_name}-bastion" })
}

# ===== Output public IP =====
output "public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}
