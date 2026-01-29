# ============================================================================
# ECS Task Definitions & CloudWatch Log Groups
# ============================================================================

resource "aws_ecs_task_definition" "this" {
  for_each = var.enabled ? toset(local.service_names) : toset([])

  family       = each.value
  network_mode = local.service_config[each.value].network_mode

  # CPU/memory from override or null (Fargate requires them)
  cpu    = try(local.service_config[each.value].cpu, null)
  memory = try(local.service_config[each.value].memory, null)

  requires_compatibilities = local.fargate_enabled ? ["FARGATE"] : ["EC2"]

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  # Load container definitions from the file path
  container_definitions = jsonencode([
    for container in jsondecode(file(
      [for def in local.service_definitions : def.file_path if def.service_name == each.value][0]
      )) : merge(
      container,

      # Safely inject logConfiguration only if it doesn't already exist
      try(lookup(container, "logConfiguration", null) == null, true) ? {
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${var.cluster_name}/${each.value}"
            "awslogs-region"        = var.region
            "awslogs-stream-prefix" = container.name
            "awslogs-create-group"  = "true"
          }
        }
      } : {}
    )
  ])
}

########################################
# CloudWatch Log Groups (one per service)
########################################
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(local.service_names)

  name              = "/ecs/${var.cluster_name}/${each.value}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(var.tags, {
    Service = each.value
  })
}
