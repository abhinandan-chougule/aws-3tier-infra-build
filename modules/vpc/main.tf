resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-igw" })
}

# Public subnets
resource "aws_subnet" "public" {
  for_each                    = toset(var.public_subnet_cidrs)
  vpc_id                      = aws_vpc.this.id
  cidr_block                  = each.value
  map_public_ip_on_launch     = true
  availability_zone           = null
  tags = merge(var.tags, { Name = "${var.project_name}-public-${replace(each.value, "/", "-")}", Tier = "public" })
}

# Private app subnets
resource "aws_subnet" "private_app" {
  for_each                = toset(var.private_app_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "${var.project_name}-private-app-${replace(each.value, "/", "-")}", Tier = "private-app" })
}

# Private db subnets
resource "aws_subnet" "private_db" {
  for_each                = toset(var.private_db_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "${var.project_name}-private-db-${replace(each.value, "/", "-")}", Tier = "private-db" })
}

# NAT Gateway with EIP in first public subnet
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.project_name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = merge(var.tags, { Name = "${var.project_name}-nat" })
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-rt-public" })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-rt-private-app" })
}

resource "aws_route" "private_app_nat" {
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_app_assoc" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-rt-private-db" })
}

resource "aws_route_table_association" "private_db_assoc" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-alb-sg" })
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "App instances SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "App from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-app-sg" })
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "DB SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "DB from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-db-sg" })
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from admin CIDR"
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
