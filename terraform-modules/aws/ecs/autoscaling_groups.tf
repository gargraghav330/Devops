# ============================================================================
# Security Group for ECS EC2 instances
# ============================================================================

resource "aws_security_group" "ecs_instances" {
  count = var.ec2_cluster_enabled ? 1 : 0

  name        = "${var.cluster_name}-ecs-instances"
  description = "Security group for ECS EC2 instances - controls host-level traffic"
  vpc_id      = var.vpc_id

  # ── All user-defined + default Ingress rules ───────────────────────────────
  dynamic "ingress" {
    for_each = var.ec2_security_group_ingress_rules

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
      description     = try(ingress.value.description, "User-defined ingress rule")
    }
  }

  # ── All user-defined + default Egress rules ────────────────────────────────
  dynamic "egress" {
    for_each = var.ec2_security_group_egress_rules

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
    Name      = "${var.cluster_name}-ecs-instances"
    Purpose   = "ECS-EC2-host"
    ManagedBy = "Terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Launch Template On-Demand & Spot EC2 instances
# ============================================================================
resource "aws_launch_template" "ec2_on_demand" {
  count = var.ec2_cluster_enabled ? 1 : 0

  name_prefix = "${var.cluster_name}-on-demand-"

  image_id      = var.ec2_ami_id
  instance_type = var.ec2_instance_type
  vpc_security_group_ids = [
    aws_security_group.ecs_instances[0].id,
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  # User data script that joins the ECS cluster
  user_data = base64encode(
    templatefile("${path.module}/user-data.tpl", {
      cluster_name                = var.cluster_name
      enable_ecs_instance_cw_logs = var.enable_ecs_instance_cw_logs
      region                      = var.region
    })
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      CapacityType = "on-demand"
    })
  }
}

resource "aws_launch_template" "ec2_spot" {
  count = var.ec2_cluster_enabled ? 1 : 0

  name_prefix = "${var.cluster_name}-spot-"

  image_id      = var.ec2_ami_id
  instance_type = var.ec2_instance_type

  vpc_security_group_ids = [
    aws_security_group.ecs_instances[0].id,
  ]

  instance_market_options {
    market_type = "spot"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  user_data = base64encode(
    templatefile("${path.module}/user-data.tpl", {
      cluster_name                = var.cluster_name
      enable_ecs_instance_cw_logs = var.enable_ecs_instance_cw_logs
      region                      = var.region
    })
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      CapacityType = "spot"
    })
  }
}

# ============================================================================
# Auto Scaling Groups for On-Demand & Spot EC2 instances
# ============================================================================

resource "aws_autoscaling_group" "ec2_on_demand" {
  count = var.ec2_cluster_enabled ? 1 : 0

  name = "${var.cluster_name}-on-demand"

  min_size         = var.ec2_on_demand_min
  max_size         = var.ec2_on_demand_max
  desired_capacity = var.ec2_on_demand_desired

  vpc_zone_identifier = var.subnets

  protect_from_scale_in = var.enable_ecs_managed_termination_protection

  dynamic "launch_template" {
    for_each = var.ec2_cluster_enabled ? [1] : []
    content {
      id      = aws_launch_template.ec2_on_demand[0].id
      version = "$Latest"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-on-demand"
    propagate_at_launch = true
  }
}

# Auto Scaling Group - Spot capacity
resource "aws_autoscaling_group" "ec2_spot" {
  count = var.ec2_cluster_enabled ? 1 : 0

  name = "${var.cluster_name}-spot"

  min_size         = var.ec2_spot_min
  max_size         = var.ec2_spot_max
  desired_capacity = var.ec2_spot_desired

  vpc_zone_identifier = var.subnets

  protect_from_scale_in = var.enable_ecs_managed_termination_protection

  dynamic "launch_template" {
    for_each = var.ec2_cluster_enabled ? [1] : []
    content {
      id      = aws_launch_template.ec2_spot[0].id
      version = "$Latest"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-spot"
    propagate_at_launch = true
  }
}
