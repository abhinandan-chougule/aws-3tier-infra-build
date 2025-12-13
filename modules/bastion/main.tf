data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux2.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name

  vpc_security_group_ids = [data.aws_security_group.bastion.id]

  tags = merge(var.tags, { Name = "${var.project_name}-bastion" })
}

data "aws_security_group" "bastion" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-bastion-sg"]
  }
  vpc_id = var.vpc_id
}

output "public_ip" {
  value = aws_instance.bastion.public_ip
}
