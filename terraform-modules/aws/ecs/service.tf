# ============================================================================
# ECS Services (Fargate + EC2 launch types)
# ============================================================================

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  count       = local.fargate_enabled || var.ec2_awsvpc_enabled ? 1 : 0
  name        = "${var.cluster_name}-ecs-tasks"
  description = "Security group for ECS tasks - controls task-level traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ecs_task_security_group_ingress_rules
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
      description     = try(ingress.value.description, "User-defined ingress rule")
    }
  }

  dynamic "egress" {
    for_each = var.ecs_task_security_group_egress_rules
    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = try(egress.value.cidr_blocks, null)
      security_groups = try(egress.value.security_groups, null)
      description     = try(egress.value.description, "User-defined egress rule")
    }
  }

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-ecs-tasks"
    Purpose   = "ECS-tasks-awsvpc"
    ManagedBy = "Terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# FARGATE SERVICES
########################################
resource "aws_ecs_service" "fargate" {
  for_each = local.fargate_enabled ? local.service_config : {}

  name            = each.key
  cluster         = aws_ecs_cluster.this[0].id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = each.value.capacity_provider_strategy.weight_normal
    base              = each.value.capacity_provider_strategy.weight_normal > 0 ? 1 : null
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = each.value.capacity_provider_strategy.weight_spot
  }

  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.ecs_tasks[0].id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = try(each.value.lb.enabled, false) ? [each.key] : []
    content {
      target_group_arn = aws_lb_target_group.this[load_balancer.value].arn
      container_name   = each.value.lb.container_name
      container_port   = each.value.lb.container_port
    }
  }



  tags = var.tags

  depends_on = [
    aws_ecs_cluster.this,
    aws_ecs_cluster_capacity_providers.fargate,
    aws_ecs_task_definition.this,
    aws_lb_listener.this,
    aws_lb_listener_rule.service_routing
  ]
  lifecycle {
    ignore_changes = [task_definition]
  }
}

########################################
# EC2 SERVICES
########################################
resource "aws_ecs_service" "ec2" {
  for_each = local.ec2_enabled ? local.service_config : {}

  name            = each.key
  cluster         = aws_ecs_cluster.this[0].id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count

  scheduling_strategy     = var.scheduling_strategy
  propagate_tags          = var.propagate_tags
  enable_ecs_managed_tags = var.enable_ecs_managed_tags

  capacity_provider_strategy {
    capacity_provider = var.ec2_on_demand_capacity_provider
    weight            = each.value.capacity_provider_strategy.weight_normal
    base              = each.value.capacity_provider_strategy.weight_normal > 0 ? 1 : null
  }

  capacity_provider_strategy {
    capacity_provider = var.ec2_spot_capacity_provider
    weight            = each.value.capacity_provider_strategy.weight_spot
  }

  dynamic "network_configuration" {
    for_each = var.ec2_awsvpc_enabled ? [1] : []
    content {
      subnets         = var.subnets
      security_groups = [aws_security_group.ecs_tasks[0].id]
    }
  }

  dynamic "load_balancer" {
    for_each = try(each.value.lb.enabled, false) ? [each.key] : []
    content {
      target_group_arn = aws_lb_target_group.this[load_balancer.value].arn
      container_name   = each.value.lb.container_name
      container_port   = each.value.lb.container_port
    }
  }


  tags = var.tags

  depends_on = [
    aws_ecs_cluster.this,
    aws_ecs_cluster_capacity_providers.ec2,
    aws_ecs_task_definition.this,
    aws_lb_listener.this,
    aws_lb_listener_rule.service_routing
  ]
  lifecycle {
    ignore_changes = [task_definition]
  }
}
