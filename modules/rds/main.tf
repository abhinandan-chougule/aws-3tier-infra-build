resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project_name}-db-subnets" })
}

data "aws_security_group" "db" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-db-sg"]
  }
  vpc_id = var.vpc_id
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project_name}-db"
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  allocated_storage       = 20
  storage_type            = "gp3"
  multi_az                = false
  publicly_accessible     = false
  vpc_security_group_ids  = [data.aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
  tags                    = merge(var.tags, { Name = "${var.project_name}-db" })
}

output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_security_group_id" {
  value = data.aws_security_group.db.id
}
