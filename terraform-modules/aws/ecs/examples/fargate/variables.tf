# ============================================================================
# variables.tf - Input Variables for ECS Cluster Module
# ============================================================================

# ── VPC Variables ────────────────────────────────────────────

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks in the VPC"
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks in the VPC"
  type        = list(string)
}

# General Settings

variable "enabled" {
  description = "Whether to create the ECS cluster and all related resources"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region where ECS resources will be created"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (used for naming, logs, capacity providers)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
# Cluster Configuration

variable "ecs_settings_enabled" {
  description = "Enable ECS Container Insights ('enabled' or 'disabled')"
  type        = string
  default     = "enabled"
}

variable "ec2_cluster_enabled" {
  description = "Enable EC2 capacity providers (ASG-backed ECS)"
  type        = bool
  default     = false
}

variable "fargate_cluster_enabled" {
  description = "Enable Fargate capacity providers"
  type        = bool
  default     = false
}

# Fargate Capacity Providers

variable "fargate_cluster_capacity_providers" {
  description = "Fargate capacity providers to associate with the cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}
# EC2 Capacity Provider Names

variable "ec2_on_demand_capacity_provider" {
  description = "Name for the EC2 on-demand capacity provider"
  type        = string
  default     = "ec2-on-demand"
}

variable "ec2_spot_capacity_provider" {
  description = "Name for the EC2 spot capacity provider"
  type        = string
  default     = "ec2-spot"
}

# Network Configuration

variable "assign_public_ip" {
  description = "Assign public IPs to ECS tasks (typically false for private subnets)"
  type        = bool
  default     = false
}

variable "network_mode" {
  description = "Network mode for ECS tasks (Fargate requires awsvpc)"
  type        = string
  default     = "awsvpc"
}

variable "ec2_awsvpc_enabled" {
  description = "Use awsvpc network mode for EC2 ECS services"
  type        = bool
  default     = true
}

# ECS Services & Task Definitions
variable "container_definitions_files" {
  description = <<EOT
List of objects. Each object creates one ECS service:
- file_path: required path to JSON container definition file
- desired_count: optional (default: 1)
- weight_normal: optional (default: 1)
- weight_spot: optional (default: 0)

Example:
[
  { file_path = "./c1.json", desired_count = 2, weight_normal = 2, weight_spot = 0 },
  { file_path = "./c2.json" }  # uses defaults
]
EOT

  type = list(object({
    file_path = string # required - path to JSON container defs

    # Service-level overrides
    service_name  = optional(string) # optional - custom service name (defaults to basename(file_path) without .json)
    desired_count = optional(number, 1)
    weight_normal = optional(number, 1)
    weight_spot   = optional(number, 0)
    network_mode  = optional(string, "awsvpc")

    # Task-level settings
    cpu    = optional(number) # task-level CPU units
    memory = optional(number) # task-level memory MiB

    # Deployment & health settings
    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_maximum_percent         = optional(number, 200)
    health_check_grace_period_seconds  = optional(number) # useful for slow-starting containers

    # Advanced service settings
    propagate_tags      = optional(string, "SERVICE") # SERVICE or TASK_DEFINITION
    scheduling_strategy = optional(string, "REPLICA") # REPLICA or DAEMON (DAEMON only for EC2)

    # Tags (if you want per-service tags)
    tags = optional(map(string), {})
    lb = optional(object({
      enabled        = bool # true = attach ALB for this service
      container_name = string
      container_port = number
      path_pattern   = optional(string, "/") # e.g. "/api/*", "/web/*", "/"
      health_check = optional(object({
        path                = optional(string, "/") # default fallback
        protocol            = optional(string, "HTTP")
        port                = optional(string, "traffic-port") # best for ECS dynamic ports
        interval            = optional(number, 30)
        timeout             = optional(number, 5)
        healthy_threshold   = optional(number, 3)
        unhealthy_threshold = optional(number, 3)
        matcher             = optional(string, "200-299")
        enabled             = optional(bool, true)
      }), {})
    }))

  }))

  default = []
}


# Default: allow HTTP (80) and HTTPS (443) from anywhere
variable "ecs_task_security_group_ingress_rules" {
  description = "List of custom ingress rules for ECS tasks security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string # tcp, udp, icmp, "-1" (all)
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
    description     = optional(string, "User-defined ingress rule")
  }))

  # Default: allow HTTP & HTTPS from anywhere
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from anywhere (default)"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere (default)"
    }
  ]
}

# Security group egress rules for ECS tasks (Fargate and EC2 awsvpc)
variable "ecs_task_security_group_egress_rules" {
  description = "List of custom egress rules for ECS tasks security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string # tcp, udp, icmp, "-1" (all)
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
    description     = optional(string, "User-defined egress rule")
  }))

  # Default: allow all outbound traffic
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic (default - required)"
    }
  ]
}

# Service Deployment Defaults

variable "scheduling_strategy" {
  description = "ECS service scheduling strategy (REPLICA or DAEMON)"
  type        = string
  default     = "REPLICA"
}

variable "propagate_tags" {
  description = "Propagate tags from SERVICE or TASK_DEFINITION"
  type        = string
  default     = "SERVICE"
}

variable "enable_ecs_managed_tags" {
  description = "Enable AWS-managed tags for ECS services and tasks"
  type        = bool
  default     = true
}


# Task Auto Scaling Settings

variable "enable_task_autoscaling" {
  description = "Enable ECS service autoscaling (CPU + memory target tracking)"
  type        = bool
  default     = false
}

variable "task_autoscaling_min_capacity" {
  description = "Minimum number of running tasks per service"
  type        = number
  default     = 1
}

variable "task_autoscaling_max_capacity" {
  description = "Maximum number of running tasks per service"
  type        = number
  default     = 10
}

# EC2 Self Managed Scaling Settings

variable "enable_ec2_self_managed_scaling" {
  description = "Enable CloudWatch + ASG based scaling for EC2 capacity providers"
  type        = bool
  default     = false
}

# Logging Settings

variable "log_retention_days" {
  description = "CloudWatch log retention period for ECS logs"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encrypting CloudWatch logs"
  type        = string
  default     = ""
}

# EC2 Configurations

variable "ec2_ami_id" {
  description = "ECS-optimized AMI ID (required only when EC2 is enabled)"
  type        = string
  default     = null
}

variable "ec2_instance_type" {
  description = "EC2 instance type for ECS nodes"
  type        = string
  default     = "t3.micro"
}

variable "enable_ecs_instance_cw_logs" {
  description = "Enable CloudWatch agent on ECS EC2 instances"
  type        = bool
  default     = true
}

# Default: allow HTTP (80) and HTTPS (443) from anywhere
variable "ec2_security_group_ingress_rules" {
  description = "List of custom ingress rules for ECS EC2 instances security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string # tcp, udp, icmp, "-1" (all)
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
    description     = optional(string, "User-defined ingress rule")
  }))

  # Default: allow HTTP & HTTPS from anywhere
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from anywhere (default)"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere (default)"
    }
  ]
}

variable "ec2_security_group_egress_rules" {
  description = "List of custom egress rules for ECS EC2 instances security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string # tcp, udp, icmp, "-1" (all)
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
    description     = optional(string, "User-defined egress rule")
  }))

  # Default: allow all outbound traffic
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic (default - required)"
    }
  ]
}

# EC2 ASG Settings

variable "ec2_on_demand_min" {
  description = "Minimum on-demand EC2 instances"
  type        = number
  default     = 0
}

variable "ec2_on_demand_max" {
  description = "Maximum on-demand EC2 instances"
  type        = number
  default     = 0
}

variable "ec2_on_demand_desired" {
  description = "Desired on-demand EC2 instances"
  type        = number
  default     = 0
}

variable "ec2_spot_min" {
  description = "Minimum spot EC2 instances"
  type        = number
  default     = 0
}

variable "ec2_spot_max" {
  description = "Maximum spot EC2 instances"
  type        = number
  default     = 0
}

variable "ec2_spot_desired" {
  description = "Desired spot EC2 instances"
  type        = number
  default     = 0
}

# Termination Policies

variable "enable_ecs_managed_termination_protection" {
  description = "Protect EC2 instances running ECS tasks from scale-in termination"
  type        = bool
  default     = true
}

# Task IAM Policies
variable "attach_base_execution_policy" {
  description = "Whether to attach the default base policy for ECS task execution (ECR pull + CloudWatch Logs)"
  type        = bool
  default     = true
}

variable "task_role_custom_policies" {
  description = "Custom policies for **task role** (application permissions: RDS IAM, S3, etc.)"
  type        = map(any)
  default     = {}
}

variable "enable_alb" {
  description = "Enable Application Load Balancer integration for ECS services"
  type        = bool
  default     = false
}

variable "alb_subnet_ids" {
  description = "Subnet IDs for ALB (public for internet-facing, private for internal)"
  type        = list(string)
  default     = [] # Use var.subnets if empty
}

variable "internal_lb" {
  description = "Internal Load Balancer"
  type        = bool
  default     = false
}
