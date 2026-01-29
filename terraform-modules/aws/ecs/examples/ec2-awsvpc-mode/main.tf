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
  vpc_id           = module.vpc.id
  subnets          = module.vpc.private_subnet_ids
  assign_public_ip = var.assign_public_ip

  ########################################
  # CLUSTER SETTINGS
  ########################################
  ecs_settings_enabled = var.ecs_settings_enabled

  # Enable EC2 cluster
  ec2_cluster_enabled = var.ec2_cluster_enabled

  ########################################
  # ECS SERVICES
  ########################################

  ecs_task_security_group_egress_rules  = var.ecs_task_security_group_egress_rules
  ecs_task_security_group_ingress_rules = var.ecs_task_security_group_ingress_rules
  container_definitions_files           = var.container_definitions_files
  enable_task_autoscaling               = var.enable_task_autoscaling
  task_autoscaling_min_capacity         = var.task_autoscaling_min_capacity
  task_autoscaling_max_capacity         = var.task_autoscaling_max_capacity
  enable_ec2_self_managed_scaling       = var.enable_ec2_self_managed_scaling

  ########################################
  # EC2 CONFIGURATION (Launch templates + ASGs)
  ########################################
  ec2_ami_id                  = data.aws_ssm_parameter.ecs_optimized_ami.value
  ec2_instance_type           = var.ec2_instance_type
  enable_ecs_instance_cw_logs = var.enable_ecs_instance_cw_logs

  ec2_security_group_ingress_rules = var.ec2_security_group_ingress_rules
  ec2_security_group_egress_rules  = var.ec2_security_group_egress_rules

  # On-demand ASG settings
  ec2_on_demand_min     = var.ec2_on_demand_min
  ec2_on_demand_max     = var.ec2_on_demand_max
  ec2_on_demand_desired = var.ec2_on_demand_desired

  # Spot ASG settings
  ec2_spot_min     = var.ec2_spot_min
  ec2_spot_max     = var.ec2_spot_max
  ec2_spot_desired = var.ec2_spot_desired

  scheduling_strategy     = var.scheduling_strategy
  propagate_tags          = var.propagate_tags
  enable_ecs_managed_tags = var.enable_ecs_managed_tags
}
