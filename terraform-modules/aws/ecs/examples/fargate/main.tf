########################################
# PROVIDER
########################################
provider "aws" {
  region = var.region
}

########################################
# TAGS
########################################
locals {
  common_tags = {
    environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Fetch the latest recommended ECS-optimized Amazon Linux 2023 AMI ID
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}


##########################################
# CALL VPC MODULE
##########################################
module "vpc" {
  source                     = "git@github.com:reventlabs/node-boilerplate.git//terraform/modules/vpc?ref=main"
  cidr_block                 = var.vpc_cidr_block
  azs                        = slice(data.aws_availability_zones.available.names, 0, 2)
  environment                = var.environment
  name                       = var.vpc_name
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  region                     = var.region
}

########################################
# CALL ECS MODULE
########################################
module "ecs" {
  source = "../../"

  ########################################
  # BASIC CONFIG
  ########################################
  enabled      = true
  cluster_name = var.cluster_name
  region       = var.region
  tags         = local.common_tags

  ########################################
  # NETWORK
  ########################################
  vpc_id  = module.vpc.id
  subnets = module.vpc.private_subnet_ids

  ########################################
  # CLUSTER SETTINGS
  ########################################
  ecs_settings_enabled = var.ecs_settings_enabled

  # Enable both cluster types
  fargate_cluster_enabled = var.fargate_cluster_enabled

  # Capacity providers for fargate
  fargate_cluster_capacity_providers = var.fargate_cluster_capacity_providers

  #ALB
  enable_alb     = true
  internal_lb    = false
  alb_subnet_ids = module.vpc.public_subnet_ids
  ########################################
  # ECS SERVICES
  ########################################

  container_definitions_files = var.container_definitions_files

  ecs_task_security_group_ingress_rules = var.ecs_task_security_group_ingress_rules
  ecs_task_security_group_egress_rules  = var.ecs_task_security_group_egress_rules

  enable_task_autoscaling       = var.enable_task_autoscaling
  task_autoscaling_min_capacity = var.task_autoscaling_min_capacity
  task_autoscaling_max_capacity = var.task_autoscaling_max_capacity

  scheduling_strategy     = var.scheduling_strategy
  propagate_tags          = var.propagate_tags
  enable_ecs_managed_tags = var.enable_ecs_managed_tags

  attach_base_execution_policy = var.attach_base_execution_policy

  # RDS IAM auth + other app permissions (task role)
  task_role_custom_policies = {
    "rds-iam-db-connect" = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid      = "AllowRDSIAMAuth"
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = "*"
      }]
    })
  }
}
