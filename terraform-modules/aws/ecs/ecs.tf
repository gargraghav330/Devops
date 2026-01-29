# ============================================================================
# ECS Cluster Creation
# ============================================================================

resource "aws_ecs_cluster" "this" {
  count = var.enabled ? 1 : 0

  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.ecs_settings_enabled
  }

  tags = merge(var.tags, {
    Name      = var.cluster_name
    ManagedBy = "terraform"
  })

  # ── Prevent invalid configuration: both Fargate and EC2 enabled at once ─────
  lifecycle {
    precondition {
      condition     = !(var.fargate_cluster_enabled && var.ec2_cluster_enabled)
      error_message = "Only one launch type (Fargate OR EC2) can be enabled at a time. Enable either fargate_cluster_enabled or ec2_cluster_enabled, but not both."
    }
  }
}

# ============================================================================
# ECS Capacity Providers - Fargate
# ============================================================================

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  count = local.fargate_enabled ? 1 : 0

  cluster_name = aws_ecs_cluster.this[0].name

  capacity_providers = var.fargate_cluster_capacity_providers

  default_capacity_provider_strategy {
    capacity_provider = var.fargate_cluster_capacity_providers[0]
    weight            = 1
  }
}

# ============================================================================
# ECS Capacity Providers - EC2 On-Demand & Spot
# ============================================================================

resource "aws_ecs_capacity_provider" "ec2_on_demand" {
  count = local.ec2_enabled ? 1 : 0

  name = var.ec2_on_demand_capacity_provider

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ec2_on_demand[0].arn
    managed_termination_protection = (var.enable_ec2_self_managed_scaling ? "DISABLED" : (var.enable_ecs_managed_termination_protection ? "ENABLED" : "DISABLED"))
    managed_scaling {
      status          = var.enable_ec2_self_managed_scaling ? "DISABLED" : "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_capacity_provider" "ec2_spot" {
  count = local.ec2_enabled ? 1 : 0

  name = var.ec2_spot_capacity_provider

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ec2_spot[0].arn
    managed_termination_protection = (var.enable_ec2_self_managed_scaling ? "DISABLED" : (var.enable_ecs_managed_termination_protection ? "ENABLED" : "DISABLED"))
    managed_scaling {
      status          = var.enable_ec2_self_managed_scaling ? "DISABLED" : "ENABLED"
      target_capacity = 100
    }
  }
}

# ============================================================================
# ECS Cluster Capacity Providers Association - EC2
# ============================================================================

resource "aws_ecs_cluster_capacity_providers" "ec2" {
  count = local.ec2_enabled ? 1 : 0

  cluster_name = aws_ecs_cluster.this[0].name

  capacity_providers = [
    aws_ecs_capacity_provider.ec2_on_demand[0].name,
    aws_ecs_capacity_provider.ec2_spot[0].name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2_on_demand[0].name
    weight            = 1
  }
}
