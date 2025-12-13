resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [] # Attach via SGs at VPC module; ALB uses them implicitly via listeners/target groups
  subnets            = var.public_subnet_ids
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "target_group_arn" { value = aws_lb_target_group.app.arn }
output "alb_dns_name"     { value = aws_lb.this.dns_name }
