# Local Variables
# Defines computed values for naming, tagging, and default trust policy

locals {
  # Role Naming
  # Constructs a unique role name using prefix, environment, and random suffix
  role_name = join("-", compact([
    var.role_name_prefix != null ? var.role_name_prefix : "role",
    var.environment != null ? var.environment : "env",
    random_string.suffix.result
  ]))

  # Validates role name length to comply with AWS limit (64 characters)
  role_name_validation = length(local.role_name) <= 64 ? local.role_name : (
    error("Role name '${local.role_name}' exceeds 64 characters")
  )

  # Default Tags
  # Merges environment, ManagedBy, and custom tags for consistent resource tagging
  default_tags = merge(
    var.environment != null ? { Environment = var.environment } : {},
    { ManagedBy = "Terraform" },
    var.tags
  )

  # Default Assume Role Policy
  # Defines a fallback trust policy if assume_role_policy is not provided
  default_assume_role_policy = {
    Version = "2012-10-17"
    Statement = length(compact([var.principal_type, var.principal_identifier])) > 0 ? [
      merge(
        {
          Effect    = "Allow"
          Principal = { (var.principal_type) = var.principal_identifier }
          Action    = "sts:AssumeRole"
        },
        var.external_id != null ? {
          Condition = {
            StringEquals = {
              "sts:ExternalId" = var.external_id
            }
          }
        } : {}
      )
    ] : []
  }
}
