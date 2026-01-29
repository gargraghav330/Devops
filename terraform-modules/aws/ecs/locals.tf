locals {
  ec2_enabled     = var.enabled && var.ec2_cluster_enabled
  fargate_enabled = var.enabled && var.fargate_cluster_enabled

  # Service name = user-provided or auto-derived from file basename (no .json)
  service_definitions = [
    for obj in var.container_definitions_files : {
      service_name  = obj.service_name != null ? obj.service_name : replace(basename(obj.file_path), ".json", "")
      file_path     = obj.file_path
      desired_count = obj.desired_count
      weight_normal = obj.weight_normal
      weight_spot   = obj.weight_spot
      cpu           = obj.cpu
      memory        = obj.memory
      network_mode  = obj.network_mode
      lb = try(obj.lb, {
        enabled        = false
        container_name = ""
        container_port = 0
      })
    }
  ]

  # Map: service_name → full config (for easy lookup)
  service_config = {
    for def in local.service_definitions : def.service_name => {
      desired_count = def.desired_count
      capacity_provider_strategy = {
        weight_normal = def.weight_normal
        weight_spot   = def.weight_spot
      }
      cpu          = def.cpu
      memory       = def.memory
      network_mode = def.network_mode
      lb           = def.lb
    }
  }

  # List of service names
  service_names = [for def in local.service_definitions : def.service_name]
}
