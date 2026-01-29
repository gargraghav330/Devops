# ============================================================================
# outputs.tf - Root / Caller Module Outputs
# ============================================================================

########################################
# CLUSTER
########################################

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.ecs_cluster_arn
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.ecs_cluster_id
}

output "ecs_capacity_providers" {
  description = "All capacity providers attached to the cluster"
  value       = module.ecs.ecs_cluster_capacity_providers
}

########################################
# SERVICES
########################################

output "ecs_service_names" {
  description = "Map of ECS service names"
  value       = module.ecs.ecs_service_names
}

output "ecs_service_arns" {
  description = "Map of ECS service ARNs"
  value       = module.ecs.ecs_service_arns
}

########################################
# NETWORKING
########################################

output "vpc_id" {
  description = "VPC ID used by ECS cluster"
  value       = module.vpc.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by ECS"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

########################################
# SECURITY GROUPS
########################################

output "ecs_task_security_group_id" {
  description = "Security group ID attached to ECS tasks (Fargate / EC2 awsvpc)"
  value       = module.ecs.ecs_task_security_group_id
}

output "ecs_instance_security_group_id" {
  description = "Security group ID attached to ECS EC2 instances"
  value       = module.ecs.ecs_instance_security_group_id
}

########################################
# EC2 INFRA (NULL SAFE)
########################################

output "ecs_ec2_on_demand_asg_name" {
  description = "On-demand EC2 ASG name (null if EC2 disabled)"
  value       = module.ecs.ecs_ec2_on_demand_asg_name
}

output "ecs_ec2_on_demand_asg_arn" {
  description = "On-demand EC2 ASG ARN (null if EC2 disabled)"
  value       = module.ecs.ecs_ec2_on_demand_asg_arn
}

output "ecs_ec2_spot_asg_name" {
  description = "Spot EC2 ASG name (null if EC2 disabled)"
  value       = module.ecs.ecs_ec2_spot_asg_name
}

output "ecs_ec2_spot_asg_arn" {
  description = "Spot EC2 ASG ARN (null if EC2 disabled)"
  value       = module.ecs.ecs_ec2_spot_asg_arn
}

########################################
# CAPACITY PROVIDERS (EC2)
########################################

output "ecs_ec2_capacity_providers" {
  description = "EC2 capacity providers (on-demand / spot)"
  value       = module.ecs.ecs_ec2_capacity_providers
}

########################################
# IAM
########################################

output "ecs_task_execution_role_arn" {
  description = "IAM role ARN used by ECS tasks"
  value       = module.ecs.ecs_task_execution_role_arn
}

output "ecs_instance_role_arn" {
  description = "IAM role ARN used by ECS EC2 instances (null for Fargate)"
  value       = module.ecs.ecs_instance_role_arn
}

output "ecs_instance_profile_name" {
  description = "IAM instance profile name for ECS EC2 instances"
  value       = module.ecs.ecs_instance_profile_name
}

########################################
# LOGGING
########################################

output "ecs_log_group_names" {
  description = "CloudWatch log groups per ECS service"
  value       = module.ecs.ecs_log_group_names
}

########################################
# ALB
########################################

output "my_alb_dns" {
  description = "Public DNS of the ALB"
  value       = module.ecs.alb.dns_name
}
