# Role Configuration
# Controls IAM role creation and core settings

variable "create_iam_role" {
  description = "Whether to create the IAM role"
  type        = bool
  default     = true
}

variable "role_name_prefix" {
  description = "Optional prefix for the IAM role name (combined with environment and random suffix)"
  type        = string
  default     = "generic-role"
  nullable    = true
  validation {
    condition     = var.role_name_prefix == null || (length(var.role_name_prefix) <= 64 && can(regex("^[a-zA-Z0-9+=,.@-]+$", var.role_name_prefix)))
    error_message = "role_name_prefix must be 64 characters or less and contain only alphanumeric characters, +=,.@-."
  }
}

variable "environment" {
  description = "Optional deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  nullable    = true
  validation {
    condition     = var.environment == null || can(regex("^[a-zA-Z0-9-]{1,32}$", var.environment))
    error_message = "environment must be 32 characters or less and contain only alphanumeric characters and hyphens."
  }
}

variable "role_description" {
  description = "Optional description for the IAM role"
  type        = string
  default     = null
  validation {
    condition     = var.role_description == null || length(var.role_description) <= 1000
    error_message = "role_description must be 1000 characters or less."
  }
}

variable "max_session_duration" {
  description = "Optional maximum session duration for the role in seconds (3600 to 43200)"
  type        = number
  default     = null
  validation {
    condition     = var.max_session_duration == null || (var.max_session_duration >= 3600 && var.max_session_duration <= 43200)
    error_message = "max_session_duration must be between 3600 and 43200 seconds or null."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional ARN of the permissions boundary policy to apply to the role"
  type        = string
  default     = null
  validation {
    condition     = var.permissions_boundary_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:policy/[a-zA-Z0-9+=,.@-]{1,128}$", var.permissions_boundary_arn))
    error_message = "permissions_boundary_arn must be a valid IAM policy ARN or null."
  }
}

# Trust Policy Configuration
# Defines who can assume the role and external ID for cross-account access

variable "assume_role_policy" {
  description = "Optional JSON policy document for the assume role trust relationship (overrides principal_type, principal_identifier, and external_id if provided)"
  type        = any
  default     = null
  validation {
    condition     = var.assume_role_policy == null || can(jsondecode(var.assume_role_policy))
    error_message = "assume_role_policy must be valid JSON or null."
  }
}

variable "principal_type" {
  description = "Type of principal for the default assume role policy (e.g., 'Service', 'AWS', 'Federated')"
  type        = string
  default     = null
  validation {
    condition     = var.principal_type == null || contains(["Service", "AWS", "Federated"], var.principal_type)
    error_message = "principal_type must be 'Service', 'AWS', or 'Federated'."
  }
}

variable "principal_identifier" {
  description = "Identifier for the principal (e.g., 'ec2.amazonaws.com', 'arn:aws:iam::123456789012:root')"
  type        = string
  default     = null
  validation {
    condition     = var.principal_identifier == null || length(var.principal_identifier) <= 512
    error_message = "principal_identifier must be 512 characters or less."
  }
}

variable "external_id" {
  description = "Optional External ID for the assume role policy (used in cross-account trust relationships)"
  type        = string
  default     = null
  validation {
    condition     = var.external_id == null || (length(var.external_id) >= 2 && length(var.external_id) <= 1224 && can(regex("^[a-zA-Z0-9-_+=,.@]+$", var.external_id)))
    error_message = "external_id must be 2 to 1224 characters and contain only alphanumeric characters, -, _, +, -, ,, ., @, =."
  }
}

# Policy Configuration
# Defines inline, managed, and standalone policies

variable "create_inline_policies" {
  description = "Whether to create inline policies for the IAM role"
  type        = bool
  default     = true
}

variable "attach_aws_managed_policies" {
  description = "Whether to attach managed policies to the IAM role"
  type        = bool
  default     = true
}

variable "policy_name_prefix" {
  description = "Optional prefix for standalone IAM policy names (combined with environment and index)"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.policy_name_prefix == null || (length(var.policy_name_prefix) <= 64 && can(regex("^[a-zA-Z0-9+=,.@-]+$", var.policy_name_prefix)))
    error_message = "policy_name_prefix must be 64 characters or less and contain only alphanumeric characters, +=,.@-."
  }
}

variable "inline_policies" {
  description = "List of inline policy documents (as JSON objects) to attach to the role"
  type        = any
  default     = []
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:aws:iam::(aws|[0-9]{12}):policy/[a-zA-Z0-9+=,.@-]{1,128}$", arn))])
    error_message = "Each managed_policy_arn must be a valid IAM policy ARN."
  }
}

variable "standalone_policies" {
  description = "List of standalone customer-managed policy documents (as JSON objects), not attached to any role"
  type = list(object({
    policy      = any
    description = optional(string, "Standalone IAM policy managed by Terraform")
  }))
  default = []
}

# Tagging
# Applies metadata to resources for organization and cost tracking

variable "tags" {
  description = "Optional additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
