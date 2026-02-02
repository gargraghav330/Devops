# Random String for Unique Naming
# Generates a 6-character suffix to ensure unique role and policy names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# IAM Role
# Creates an IAM role with customizable trust policy, description, and permissions boundary
resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  # Required attributes
  name               = local.role_name
  assume_role_policy = var.assume_role_policy != null ? var.assume_role_policy : jsonencode(local.default_assume_role_policy)

  # Optional attributes
  description          = var.role_description
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn

  # Tags for organization and tracking
  tags = local.default_tags

  # Lifecycle rule to ignore tag changes made outside Terraform
  lifecycle {
    ignore_changes = [tags]
  }
}

# Inline Policies
# Attaches custom inline policies directly to the IAM role
resource "aws_iam_role_policy" "inline" {
  for_each = var.create_inline_policies && length(var.inline_policies) > 0 ? { for idx, policy in var.inline_policies : idx => policy } : {}

  name   = "${local.role_name}-inline-${each.key}"
  role   = aws_iam_role.this[0].id
  policy = jsonencode(each.value)
}

# Managed Policy Attachments
# Attaches AWS or customer-managed policies to the IAM role
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.attach_aws_managed_policies && length(var.managed_policy_arns) > 0 ? toset(var.managed_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# Standalone Customer-Managed Policies
# Creates policies not attached to any role, for use by other entities
resource "aws_iam_policy" "standalone" {
  for_each = length(var.standalone_policies) > 0 ? { for idx, policy in var.standalone_policies : idx => policy } : {}

  # Required attributes
  name   = "${var.policy_name_prefix != null ? var.policy_name_prefix : local.role_name}-policy-${each.key}"
  policy = jsonencode(each.value.policy)

  # Optional attributes
  description = lookup(each.value, "description", "Standalone IAM policy managed by Terraform")

  # Tags for organization and tracking
  tags = local.default_tags
}
