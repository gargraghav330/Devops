# ============================================================================
# ECS Task Autoscaling (CPU + Memory Target Tracking)
# Applied to ALL services when enable_task_autoscaling = true
# Works identically for Fargate and EC2 launch types
# ============================================================================


# 1. Scalable Target (DesiredCount) - min 1, max 10
resource "aws_appautoscaling_target" "ecs_service" {
  for_each = var.enable_task_autoscaling ? toset(local.service_names) : toset([])

  max_capacity       = var.task_autoscaling_max_capacity
  min_capacity       = var.task_autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this[0].name}/${each.value}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    ignore_changes = [min_capacity, max_capacity]
  }
  depends_on = [
    aws_ecs_service.fargate[0],
    aws_ecs_service.ec2[0]
  ]
}


# 2. CPU Target Tracking Policy (70%)
resource "aws_appautoscaling_policy" "cpu_target" {
  for_each = aws_appautoscaling_target.ecs_service

  name               = "${each.key}-cpu-target-70"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# 3. Memory Target Tracking Policy (70%)
resource "aws_appautoscaling_policy" "memory_target" {
  for_each = aws_appautoscaling_target.ecs_service

  name               = "${each.key}-memory-target-70"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# ============================================================================
# ECS Infra Autoscaling Self Managed
# Works only for EC2 launch types
# ============================================================================

locals {
  self_managed_enabled = var.enable_ec2_self_managed_scaling && local.ec2_enabled
}

# ── Scale-Up Policy - On-Demand ──────────────────────────────────────────────
resource "aws_autoscaling_policy" "on_demand_scale_up" {
  count = local.self_managed_enabled ? 1 : 0

  name                   = "${var.cluster_name}-on-demand-scale-up"
  scaling_adjustment     = 1 # Add 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_on_demand[0].name
}

# ── Scale-Down Policy - On-Demand ────────────────────────────────────────────
resource "aws_autoscaling_policy" "on_demand_scale_down" {
  count = local.self_managed_enabled ? 1 : 0

  name                   = "${var.cluster_name}-on-demand-scale-down"
  scaling_adjustment     = -1 # Remove 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_on_demand[0].name
}

# ── Scale-Up Policy - Spot ───────────────────────────────────────────────────
resource "aws_autoscaling_policy" "spot_scale_up" {
  count = local.self_managed_enabled ? 1 : 0

  name                   = "${var.cluster_name}-spot-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_spot[0].name
}

# ── Scale-Down Policy - Spot ─────────────────────────────────────────────────
resource "aws_autoscaling_policy" "spot_scale_down" {
  count = local.self_managed_enabled ? 1 : 0

  name                   = "${var.cluster_name}-spot-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ec2_spot[0].name
}

# ============================================================================
# CloudWatch Alarms for ECS Infra Autoscaling
# Works only for EC2 launch types
# ============================================================================

# CPU High Alarm - Scale Up (both on-demand and spot)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = local.self_managed_enabled ? 1 : 0

  alarm_name          = "${var.cluster_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupAverageCPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 70
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.ec2_on_demand[0].name }
  alarm_actions = [
    aws_autoscaling_policy.on_demand_scale_up[0].arn,
    aws_autoscaling_policy.spot_scale_up[0].arn
  ]
  tags = var.tags

  depends_on = [
    aws_autoscaling_policy.on_demand_scale_up,
    aws_autoscaling_policy.spot_scale_up
  ]
}

# CPU Low Alarm - Scale Down
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = local.self_managed_enabled ? 1 : 0

  alarm_name          = "${var.cluster_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupAverageCPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.ec2_spot[0].name }
  alarm_actions = [
    aws_autoscaling_policy.on_demand_scale_down[0].arn,
    aws_autoscaling_policy.spot_scale_down[0].arn
  ]
  tags = var.tags

  depends_on = [
    aws_autoscaling_policy.on_demand_scale_down,
    aws_autoscaling_policy.spot_scale_down
  ]
}
