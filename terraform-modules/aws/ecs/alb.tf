locals {
  alb_enabled = var.enable_alb
}

# ALB Security Group (allows HTTP/HTTPS ingress)
resource "aws_security_group" "alb" {
  count       = local.alb_enabled ? 1 : 0
  name        = "${var.cluster_name}-alb"
  description = "Security group for ECS ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_security_group_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = try(ingress.value.cidr_blocks, ["0.0.0.0/0"])
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-alb" })
}

# Application Load Balancer
resource "aws_lb" "this" {
  count              = local.alb_enabled ? 1 : 0
  name               = "${var.cluster_name}-alb"
  internal           = var.internal_lb
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = length(var.alb_subnet_ids) > 0 ? var.alb_subnet_ids : var.subnets

  tags = merge(var.tags, { Name = "${var.cluster_name}-alb" })
}

# Target Group per Service (dynamic ports for ECS)
resource "aws_lb_target_group" "this" {
  for_each = {
    for name, svc in local.service_config :
    name => svc
    if local.alb_enabled && try(svc.lb.enabled, false)
  }

  name        = "${each.key}-tg"
  port        = 80 # Dynamic – ECS handles mapping
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = try(each.value.lb.health_check.enabled, true)
    path                = try(each.value.lb.health_check.path, "/health")
    protocol            = try(each.value.lb.health_check.protocol, "HTTP")
    port                = try(each.value.lb.health_check.port, "traffic-port")
    interval            = try(each.value.lb.health_check.interval, 30)
    timeout             = try(each.value.lb.health_check.timeout, 5)
    healthy_threshold   = try(each.value.lb.health_check.healthy_threshold, 3)
    unhealthy_threshold = try(each.value.lb.health_check.unhealthy_threshold, 3)
    matcher             = try(each.value.lb.health_check.matcher, "200-299")
  }

  tags       = merge(var.tags, { Service = each.key })
  depends_on = [aws_lb.this]
}

# ALB Listener (HTTP example – add HTTPS if needed)
resource "aws_lb_listener" "this" {
  count             = local.alb_enabled ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No route matched - 404"
      status_code  = "404"
    }
  }
  depends_on = [aws_lb.this]
}

resource "aws_lb_listener_rule" "service_routing" {
  for_each = {
    for name, svc in local.service_config :
    name => svc
    if local.alb_enabled && try(svc.lb.enabled, false)
  }
  listener_arn = aws_lb_listener.this[0].arn
  priority     = index(sort(keys(local.service_config)), each.key) + 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.lb.path_pattern]
    }
  }
}

# Automatically allow traffic from ALB security group to ECS tasks
# (only when ALB is enabled and at least one service uses LB)
resource "aws_security_group_rule" "ecs_tasks_from_alb" {
  count = local.alb_enabled && length([
    for svc in local.service_config : svc
    if try(svc.lb.enabled, false)
  ]) > 0 ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[0].id
  description              = "Allow inbound from ALB "
  security_group_id        = aws_security_group.ecs_tasks[0].id
}
