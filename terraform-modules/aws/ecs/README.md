# ECS Terraform Module (Fargate & EC2)

## Overview

This module provisions an **AWS ECS cluster** that supports:

* **Fargate**
* **EC2 (On-Demand + Spot)**
* **ECS-managed infrastructure scaling**
* **Self-managed EC2 scaling**
* **Task autoscaling (CPU & Memory)**
* **Container definitions loaded purely from JSON files**
* **Multiple containers per service supported**
* **Security groups: dynamic user rules + secure defaults**

### Examples & Complete Usage

For complete, ready-to-run examples and Terraform apply instructions for:

- Fargate
- EC2 (awsvpc & bridge modes)

refer to the dedicated examples guide:

**[ECS Examples Deployment Guide](./examples/README.md)**

## Usage

### Basic Fargate Provisioning (Recommended Starting Point)

Create a simple Fargate-only ECS cluster with one service using a JSON file for container definitions.

```hcl
module "ecs" {
  source = "git@github.com:reventlabs/iaac.git//terraform/modules/aws/ecs?ref=main"

  enabled      = true
  cluster_name = "my-fargate-app"
  region       = "eu-central-1"

  vpc_id   = module.vpc.id
  subnets  = module.vpc.private_subnet_ids

  fargate_cluster_enabled = true
  ec2_cluster_enabled     = false

  container_definitions_files = [
    {
      file_path     = "${path.module}/task-definition.json"  # Your JSON file
      desired_count = 2
      weight_normal = 1
      weight_spot   = 1
    }
  ]

  enable_task_autoscaling = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

**Example `task-definition.json`**:

```json
[
  {
    "name": "web",
    "image": "nginx:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.28.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.cpu_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.memory_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_autoscaling_group.ec2_on_demand](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.ec2_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.on_demand_scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.on_demand_scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.spot_scale_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.spot_scale_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cpu_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_capacity_provider.ec2_on_demand](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_capacity_provider.ec2_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_cluster_capacity_providers.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_ecs_service.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_instance_profile.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ecs_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_task_execution_base](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.execution_custom_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_custom_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_instance_role_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_instance_role_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.execution_custom_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_custom_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.ec2_on_demand](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_launch_template.ec2_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.service_routing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ecs_tasks_from_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_listener_port"></a> [alb\_listener\_port](#input\_alb\_listener\_port) | ALB listener port (80 for HTTP, 443 for HTTPS) | `number` | `80` | no |
| <a name="input_alb_security_group_ingress_rules"></a> [alb\_security\_group\_ingress\_rules](#input\_alb\_security\_group\_ingress\_rules) | Ingress rules for ALB security group (e.g., HTTP/HTTPS from 0.0.0.0/0) | <pre>list(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = optional(list(string))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "from_port": 80,<br/>    "protocol": "tcp",<br/>    "to_port": 80<br/>  },<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "to_port": 443<br/>  }<br/>]</pre> | no |
| <a name="input_alb_subnet_ids"></a> [alb\_subnet\_ids](#input\_alb\_subnet\_ids) | Subnet IDs for ALB (public for internet-facing, private for internal) | `list(string)` | `[]` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign public IPs to ECS tasks (typically false for private subnets) | `bool` | `false` | no |
| <a name="input_attach_base_execution_policy"></a> [attach\_base\_execution\_policy](#input\_attach\_base\_execution\_policy) | Whether to attach the default base policy for ECS task execution (ECR pull + CloudWatch Logs) | `bool` | `true` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the ECS cluster (used for naming, logs, capacity providers) | `string` | n/a | yes |
| <a name="input_container_definitions_files"></a> [container\_definitions\_files](#input\_container\_definitions\_files) | List of objects. Each object creates one ECS service:<br/>- file\_path: required path to JSON container definition file<br/>- desired\_count: optional (default: 1)<br/>- weight\_normal: optional (default: 1)<br/>- weight\_spot: optional (default: 0)<br/><br/>Example:<br/>[<br/>  { file\_path = "./c1.json", desired\_count = 2, weight\_normal = 2, weight\_spot = 0 },<br/>  { file\_path = "./c2.json" }  # uses defaults<br/>] | <pre>list(object({<br/>    file_path = string # required - path to JSON container defs<br/><br/>    # Service-level overrides<br/>    service_name  = optional(string) # optional - custom service name (defaults to basename(file_path) without .json)<br/>    desired_count = optional(number, 1)<br/>    weight_normal = optional(number, 1)<br/>    weight_spot   = optional(number, 0)<br/>    network_mode  = optional(string, "awsvpc")<br/><br/>    # Task-level settings<br/>    cpu    = number # task-level CPU units<br/>    memory = number # task-level memory MiB<br/><br/>    # Deployment & health settings<br/>    deployment_minimum_healthy_percent = optional(number, 100)<br/>    deployment_maximum_percent         = optional(number, 200)<br/>    health_check_grace_period_seconds  = optional(number) # useful for slow-starting containers<br/><br/>    # Advanced service settings<br/>    propagate_tags      = optional(string, "SERVICE") # SERVICE or TASK_DEFINITION<br/>    scheduling_strategy = optional(string, "REPLICA") # REPLICA or DAEMON (DAEMON only for EC2)<br/><br/>    # Tags (if you want per-service tags)<br/>    tags = optional(map(string), {})<br/><br/>    lb = optional(object({<br/>      enabled        = bool # true = attach ALB for this service<br/>      container_name = string<br/>      container_port = number<br/>      path_pattern   = optional(string, "/") # e.g. "/api/*", "/web/*", "/"<br/>      health_check = optional(object({<br/>        path                = optional(string, "/") # default fallback<br/>        protocol            = optional(string, "HTTP")<br/>        port                = optional(string, "traffic-port") # best for ECS dynamic ports<br/>        interval            = optional(number, 30)<br/>        timeout             = optional(number, 5)<br/>        healthy_threshold   = optional(number, 3)<br/>        unhealthy_threshold = optional(number, 3)<br/>        matcher             = optional(string, "200-299")<br/>        enabled             = optional(bool, true)<br/>      }), {})<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_ec2_ami_id"></a> [ec2\_ami\_id](#input\_ec2\_ami\_id) | ECS-optimized AMI ID (required only when EC2 is enabled) | `string` | `null` | no |
| <a name="input_ec2_awsvpc_enabled"></a> [ec2\_awsvpc\_enabled](#input\_ec2\_awsvpc\_enabled) | Use awsvpc network mode for EC2 ECS services | `bool` | `true` | no |
| <a name="input_ec2_cluster_enabled"></a> [ec2\_cluster\_enabled](#input\_ec2\_cluster\_enabled) | Enable EC2 capacity providers (ASG-backed ECS) | `bool` | `false` | no |
| <a name="input_ec2_instance_type"></a> [ec2\_instance\_type](#input\_ec2\_instance\_type) | EC2 instance type for ECS nodes | `string` | `"t3.micro"` | no |
| <a name="input_ec2_on_demand_capacity_provider"></a> [ec2\_on\_demand\_capacity\_provider](#input\_ec2\_on\_demand\_capacity\_provider) | Name for the EC2 on-demand capacity provider | `string` | `"ec2-on-demand"` | no |
| <a name="input_ec2_on_demand_desired"></a> [ec2\_on\_demand\_desired](#input\_ec2\_on\_demand\_desired) | Desired on-demand EC2 instances | `number` | `0` | no |
| <a name="input_ec2_on_demand_max"></a> [ec2\_on\_demand\_max](#input\_ec2\_on\_demand\_max) | Maximum on-demand EC2 instances | `number` | `0` | no |
| <a name="input_ec2_on_demand_min"></a> [ec2\_on\_demand\_min](#input\_ec2\_on\_demand\_min) | Minimum on-demand EC2 instances | `number` | `0` | no |
| <a name="input_ec2_security_group_egress_rules"></a> [ec2\_security\_group\_egress\_rules](#input\_ec2\_security\_group\_egress\_rules) | List of custom egress rules for ECS EC2 instances security group | <pre>list(object({<br/>    from_port       = number<br/>    to_port         = number<br/>    protocol        = string # tcp, udp, icmp, "-1" (all)<br/>    cidr_blocks     = optional(list(string))<br/>    security_groups = optional(list(string))<br/>    description     = optional(string, "User-defined egress rule")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow all outbound traffic (default - required)",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| <a name="input_ec2_security_group_ingress_rules"></a> [ec2\_security\_group\_ingress\_rules](#input\_ec2\_security\_group\_ingress\_rules) | List of custom ingress rules for ECS EC2 instances security group | <pre>list(object({<br/>    from_port       = number<br/>    to_port         = number<br/>    protocol        = string # tcp, udp, icmp, "-1" (all)<br/>    cidr_blocks     = optional(list(string))<br/>    security_groups = optional(list(string))<br/>    description     = optional(string, "User-defined ingress rule")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow HTTP from anywhere (default)",<br/>    "from_port": 80,<br/>    "protocol": "tcp",<br/>    "to_port": 80<br/>  },<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow HTTPS from anywhere (default)",<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "to_port": 443<br/>  }<br/>]</pre> | no |
| <a name="input_ec2_spot_capacity_provider"></a> [ec2\_spot\_capacity\_provider](#input\_ec2\_spot\_capacity\_provider) | Name for the EC2 spot capacity provider | `string` | `"ec2-spot"` | no |
| <a name="input_ec2_spot_desired"></a> [ec2\_spot\_desired](#input\_ec2\_spot\_desired) | Desired spot EC2 instances | `number` | `0` | no |
| <a name="input_ec2_spot_max"></a> [ec2\_spot\_max](#input\_ec2\_spot\_max) | Maximum spot EC2 instances | `number` | `0` | no |
| <a name="input_ec2_spot_min"></a> [ec2\_spot\_min](#input\_ec2\_spot\_min) | Minimum spot EC2 instances | `number` | `0` | no |
| <a name="input_ecs_settings_enabled"></a> [ecs\_settings\_enabled](#input\_ecs\_settings\_enabled) | Enable ECS Container Insights ('enabled' or 'disabled') | `string` | `"enabled"` | no |
| <a name="input_ecs_task_security_group_egress_rules"></a> [ecs\_task\_security\_group\_egress\_rules](#input\_ecs\_task\_security\_group\_egress\_rules) | List of custom egress rules for ECS tasks security group | <pre>list(object({<br/>    from_port       = number<br/>    to_port         = number<br/>    protocol        = string # tcp, udp, icmp, "-1" (all)<br/>    cidr_blocks     = optional(list(string))<br/>    security_groups = optional(list(string))<br/>    description     = optional(string, "User-defined egress rule")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow all outbound traffic (default - required)",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| <a name="input_ecs_task_security_group_ingress_rules"></a> [ecs\_task\_security\_group\_ingress\_rules](#input\_ecs\_task\_security\_group\_ingress\_rules) | List of custom ingress rules for ECS tasks security group | <pre>list(object({<br/>    from_port       = number<br/>    to_port         = number<br/>    protocol        = string # tcp, udp, icmp, "-1" (all)<br/>    cidr_blocks     = optional(list(string))<br/>    security_groups = optional(list(string))<br/>    description     = optional(string, "User-defined ingress rule")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow HTTP from anywhere (default)",<br/>    "from_port": 80,<br/>    "protocol": "tcp",<br/>    "to_port": 80<br/>  },<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow HTTPS from anywhere (default)",<br/>    "from_port": 443,<br/>    "protocol": "tcp",<br/>    "to_port": 443<br/>  }<br/>]</pre> | no |
| <a name="input_enable_alb"></a> [enable\_alb](#input\_enable\_alb) | Enable Application Load Balancer integration for ECS services | `bool` | `false` | no |
| <a name="input_enable_ec2_self_managed_scaling"></a> [enable\_ec2\_self\_managed\_scaling](#input\_enable\_ec2\_self\_managed\_scaling) | Enable CloudWatch + ASG based scaling for EC2 capacity providers | `bool` | `false` | no |
| <a name="input_enable_ecs_instance_cw_logs"></a> [enable\_ecs\_instance\_cw\_logs](#input\_enable\_ecs\_instance\_cw\_logs) | Enable CloudWatch agent on ECS EC2 instances | `bool` | `true` | no |
| <a name="input_enable_ecs_managed_tags"></a> [enable\_ecs\_managed\_tags](#input\_enable\_ecs\_managed\_tags) | Enable AWS-managed tags for ECS services and tasks | `bool` | `true` | no |
| <a name="input_enable_ecs_managed_termination_protection"></a> [enable\_ecs\_managed\_termination\_protection](#input\_enable\_ecs\_managed\_termination\_protection) | Protect EC2 instances running ECS tasks from scale-in termination | `bool` | `true` | no |
| <a name="input_enable_task_autoscaling"></a> [enable\_task\_autoscaling](#input\_enable\_task\_autoscaling) | Enable ECS service autoscaling (CPU + memory target tracking) | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the ECS cluster and all related resources | `bool` | `false` | no |
| <a name="input_execution_role_custom_policies"></a> [execution\_role\_custom\_policies](#input\_execution\_role\_custom\_policies) | Custom policies to attach to the ECS **task execution role**. Supports both ARN (managed policies) and inline JSON policies. | `map(any)` | `{}` | no |
| <a name="input_fargate_cluster_capacity_providers"></a> [fargate\_cluster\_capacity\_providers](#input\_fargate\_cluster\_capacity\_providers) | Fargate capacity providers to associate with the cluster | `list(string)` | <pre>[<br/>  "FARGATE",<br/>  "FARGATE_SPOT"<br/>]</pre> | no |
| <a name="input_fargate_cluster_enabled"></a> [fargate\_cluster\_enabled](#input\_fargate\_cluster\_enabled) | Enable Fargate capacity providers | `bool` | `false` | no |
| <a name="input_internal_lb"></a> [internal\_lb](#input\_internal\_lb) | Internal Load Balancer | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for encrypting CloudWatch logs | `string` | `""` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention period for ECS logs | `number` | `30` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Network mode for ECS tasks (Fargate requires awsvpc) | `string` | `"awsvpc"` | no |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | Propagate tags from SERVICE or TASK\_DEFINITION | `string` | `"SERVICE"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where ECS resources will be created | `string` | n/a | yes |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | ECS service scheduling strategy (REPLICA or DAEMON) | `string` | `"REPLICA"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnet IDs for ECS tasks / EC2 instances | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags applied to all resources | `map(string)` | `{}` | no |
| <a name="input_task_autoscaling_max_capacity"></a> [task\_autoscaling\_max\_capacity](#input\_task\_autoscaling\_max\_capacity) | Maximum number of running tasks per service | `number` | `10` | no |
| <a name="input_task_autoscaling_min_capacity"></a> [task\_autoscaling\_min\_capacity](#input\_task\_autoscaling\_min\_capacity) | Minimum number of running tasks per service | `number` | `1` | no |
| <a name="input_task_role_custom_policies"></a> [task\_role\_custom\_policies](#input\_task\_role\_custom\_policies) | Custom policies for **task role** (application permissions: RDS IAM, S3, etc.) | `map(any)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where ECS cluster and resources will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb"></a> [alb](#output\_alb) | Full ALB configuration (if enabled) |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS cluster |
| <a name="output_ecs_cluster_capacity_providers"></a> [ecs\_cluster\_capacity\_providers](#output\_ecs\_cluster\_capacity\_providers) | Capacity providers associated with the ECS cluster |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ID of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster |
| <a name="output_ecs_ec2_capacity_providers"></a> [ecs\_ec2\_capacity\_providers](#output\_ecs\_ec2\_capacity\_providers) | EC2 capacity provider names (on-demand + spot) |
| <a name="output_ecs_ec2_on_demand_asg_arn"></a> [ecs\_ec2\_on\_demand\_asg\_arn](#output\_ecs\_ec2\_on\_demand\_asg\_arn) | On-demand EC2 Auto Scaling Group ARN |
| <a name="output_ecs_ec2_on_demand_asg_name"></a> [ecs\_ec2\_on\_demand\_asg\_name](#output\_ecs\_ec2\_on\_demand\_asg\_name) | On-demand EC2 Auto Scaling Group name |
| <a name="output_ecs_ec2_spot_asg_arn"></a> [ecs\_ec2\_spot\_asg\_arn](#output\_ecs\_ec2\_spot\_asg\_arn) | Spot EC2 Auto Scaling Group ARN |
| <a name="output_ecs_ec2_spot_asg_name"></a> [ecs\_ec2\_spot\_asg\_name](#output\_ecs\_ec2\_spot\_asg\_name) | Spot EC2 Auto Scaling Group name |
| <a name="output_ecs_instance_profile_name"></a> [ecs\_instance\_profile\_name](#output\_ecs\_instance\_profile\_name) | IAM instance profile name for ECS EC2 instances |
| <a name="output_ecs_instance_role_arn"></a> [ecs\_instance\_role\_arn](#output\_ecs\_instance\_role\_arn) | IAM role ARN used by ECS EC2 instances |
| <a name="output_ecs_instance_security_group_id"></a> [ecs\_instance\_security\_group\_id](#output\_ecs\_instance\_security\_group\_id) | Security group ID attached to ECS EC2 instances |
| <a name="output_ecs_log_group_names"></a> [ecs\_log\_group\_names](#output\_ecs\_log\_group\_names) | CloudWatch log group names per ECS service |
| <a name="output_ecs_service_arns"></a> [ecs\_service\_arns](#output\_ecs\_service\_arns) | Map of ECS service ARNs |
| <a name="output_ecs_service_names"></a> [ecs\_service\_names](#output\_ecs\_service\_names) | List of all ECS service names (derived from container\_definitions\_files keys) |
| <a name="output_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#output\_ecs\_task\_execution\_role\_arn) | IAM role ARN used by ECS tasks (execution role) |
| <a name="output_ecs_task_security_group_id"></a> [ecs\_task\_security\_group\_id](#output\_ecs\_task\_security\_group\_id) | Security group ID attached to ECS tasks (awsvpc mode) |
<!-- END_TF_DOCS -->


### Testing Checklist (Quick & Practical)

See the `ecs/examples/` directory for complete working configurations:

- **ec2-awsvpc-mode**
  Production-ready EC2 cluster using awsvpc networking mode (recommended)

- **ec2-bridge-mode**
  Legacy EC2 cluster using bridge networking mode

- **fargate**
  Simple Fargate-only cluster

All examples use the relative path `source = "../../"` to reference the module from the examples directory.

### Important Notes

- **Private subnets required** for EC2 + awsvpc mode (no public IP allowed on tasks)
- **assign_public_ip = false** enforced for EC2 (AWS forbids it)
- JSON file **must** contain valid ECS container definition array
- If JSON omits `logConfiguration` → module auto-adds `awslogs` with correct group/region
- `cpu`/`memory` at task level required for Fargate must be provided in file or per-service override
- Capacity provider names are fixed — do not change once created
