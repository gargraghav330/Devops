# ============================================================================
# outputs.tf - ECS Cluster Module Outputs
# ============================================================================

########################################
# ECS CLUSTER
########################################

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this[0].name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this[0].arn
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this[0].id
}

output "ecs_cluster_capacity_providers" {
  description = "Capacity providers associated with the ECS cluster"
  value = concat(
    local.ec2_enabled ? [
      aws_ecs_capacity_provider.ec2_on_demand[0].name,
      aws_ecs_capacity_provider.ec2_spot[0].name
    ] : [],
    local.fargate_enabled ? var.fargate_cluster_capacity_providers : []
  )
}

########################################
# EC2 AUTO SCALING GROUPS (INFRA)
########################################

output "ecs_ec2_on_demand_asg_name" {
  description = "On-demand EC2 Auto Scaling Group name"
  value       = local.ec2_enabled ? aws_autoscaling_group.ec2_on_demand[0].name : null
}

output "ecs_ec2_on_demand_asg_arn" {
  description = "On-demand EC2 Auto Scaling Group ARN"
  value       = local.ec2_enabled ? aws_autoscaling_group.ec2_on_demand[0].arn : null
}

output "ecs_ec2_spot_asg_name" {
  description = "Spot EC2 Auto Scaling Group name"
  value       = local.ec2_enabled ? aws_autoscaling_group.ec2_spot[0].name : null
}

output "ecs_ec2_spot_asg_arn" {
  description = "Spot EC2 Auto Scaling Group ARN"
  value       = local.ec2_enabled ? aws_autoscaling_group.ec2_spot[0].arn : null
}

########################################
# ECS CAPACITY PROVIDERS (EC2)
########################################

output "ecs_ec2_capacity_providers" {
  description = "EC2 capacity provider names (on-demand + spot)"
  value = local.ec2_enabled ? {
    on_demand = aws_ecs_capacity_provider.ec2_on_demand[0].name
    spot      = aws_ecs_capacity_provider.ec2_spot[0].name
  } : {}
}

########################################
# ECS SERVICES
########################################

output "ecs_service_names" {
  description = "List of all ECS service names (derived from container_definitions_files keys)"
  value       = local.service_names # ← uses the computed local
}

output "ecs_service_arns" {
  description = "Map of ECS service ARNs"
  value = merge(
    local.ec2_enabled ? {
      for k, v in aws_ecs_service.ec2 :
      k => v.arn
    } : {},
    local.fargate_enabled ? {
      for k, v in aws_ecs_service.fargate :
      k => v.arn
    } : {}
  )
}

########################################
# IAM ROLES
########################################

output "ecs_task_execution_role_arn" {
  description = "IAM role ARN used by ECS tasks (execution role)"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_instance_role_arn" {
  description = "IAM role ARN used by ECS EC2 instances"
  value       = local.ec2_enabled ? aws_iam_role.ecs_instance_role.arn : null
}

output "ecs_instance_profile_name" {
  description = "IAM instance profile name for ECS EC2 instances"
  value       = local.ec2_enabled ? aws_iam_instance_profile.ecs_instance.name : null
}

########################################
# NETWORKING / SECURITY
########################################

output "ecs_task_security_group_id" {
  description = "Security group ID attached to ECS tasks (awsvpc mode)"
  value       = (local.fargate_enabled || var.ec2_awsvpc_enabled) ? aws_security_group.ecs_tasks[0].id : null
}

output "ecs_instance_security_group_id" {
  description = "Security group ID attached to ECS EC2 instances"
  value       = local.ec2_enabled ? aws_security_group.ecs_instances[0].id : null
}

########################################
# LOGGING
########################################

output "ecs_log_group_names" {
  description = "CloudWatch log group names per ECS service"
  value = {
    for k, lg in aws_cloudwatch_log_group.this :
    k => lg.name
  }
}

########################################
# ALB
########################################
# ── ALB Outputs ──────────────────────────────────────────────────────────────

output "alb" {
  description = "Full ALB configuration (if enabled)"
  value = local.alb_enabled ? {
    dns_name          = aws_lb.this[0].dns_name
    arn               = aws_lb.this[0].arn
    zone_id           = aws_lb.this[0].zone_id
    listener_arn      = aws_lb_listener.this[0].arn
    target_groups     = { for name in local.service_names : name => aws_lb_target_group.this[name].arn }
    security_group_id = aws_security_group.alb[0].id
  } : null
}
