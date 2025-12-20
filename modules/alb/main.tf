resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id] # ALB security group from VPC
  subnets            = distinct(var.public_subnet_ids) # Ensure only one subnet per AZ
  idle_timeout       = 60
  tags               = merge(var.tags, { Name = "${var.project_name}-alb" })
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    path                = "/actuator/health"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = merge(var.tags, { Name = "${var.project_name}-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "target_group_arn" { value = aws_lb_target_group.app.arn }
output "alb_dns_name"     { value = aws_lb.this.dns_name }
output "alb_name"        { value = aws_lb.this.name }
output "tg_name"         { value = aws_lb_target_group.app.name }
