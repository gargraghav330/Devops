# ============================================================================
# iam.tf - IAM Roles & Instance Profile for ECS Tasks and EC2 Instances
# ============================================================================

# ── Task Execution Role (used by ECS agent/containers to pull images, logs, secrets) ──
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# 1. BASE policy (ECR + CloudWatch Logs) – controlled using var.attach_base_execution_policy
resource "aws_iam_role_policy" "ecs_task_execution_base" {
  count = var.attach_base_execution_policy ? 1 : 0

  name = "${var.cluster_name}-task-execution-base"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR – required to pull images from private ECR
      {
        Sid    = "ECRImagePull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },

      # CloudWatch Logs – send container logs
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/ecs/*:*" # More precise wildcard
      },
    ]
  })
}
# 2. Custom managed policies (ARNs) – user can pass AWS managed or customer managed policy ARNs
resource "aws_iam_role_policy_attachment" "execution_custom_arn" {
  for_each = {
    for k, v in var.execution_role_custom_policies :
    k => v
    if can(regex("^arn:aws:iam::[0-9]{12}:policy/", v)) || can(regex("^arn:aws:iam::aws:policy/", v))
  }

  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = each.value
}

# 3. Custom inline policies (JSON documents) – user can pass raw policy JSON
resource "aws_iam_role_policy" "execution_custom_inline" {
  for_each = {
    for k, v in var.execution_role_custom_policies :
    k => v
    if !can(regex("^arn:", v)) # Anything not starting with arn: is assumed to be inline JSON
  }

  name   = "${var.cluster_name}-${each.key}"
  role   = aws_iam_role.ecs_task_execution.id
  policy = each.value # Expects valid JSON string
}

# ── Separate Task Role  ───────────────────────────────────────
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Custom policies for task role (RDS IAM goes here!)
resource "aws_iam_role_policy" "task_custom_inline" {
  for_each = { for k, v in var.task_role_custom_policies : k => v if !can(regex("^arn:", v)) }
  name     = "${var.cluster_name}-${each.key}"
  role     = aws_iam_role.ecs_task_role.id
  policy   = each.value
}

resource "aws_iam_role_policy_attachment" "task_custom_arn" {
  for_each   = { for k, v in var.task_role_custom_policies : k => v if can(regex("^arn:", v)) }
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = each.value
}


# ── ECS Instance Role (only for EC2 launch type) ────────────────────────────
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.cluster_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# required managed policies for ECS Instance Role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_ecs" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_ecr" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# resource "aws_iam_role_policy_attachment" "ecs_instance_role_ssm" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# Instance Profile used by EC2 ECS instances
resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}
