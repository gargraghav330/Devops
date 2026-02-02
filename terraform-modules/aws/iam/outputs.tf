# ======================================================
# IAM ROLE OUTPUTS
# ======================================================

output "role_name" {
  description = "Name of the created IAM role"
  value       = var.create_iam_role ? aws_iam_role.this[0].name : null
}

output "role_arn" {
  description = "ARN of the created IAM role"
  value       = var.create_iam_role ? aws_iam_role.this[0].arn : null
}

output "inline_policy_names" {
  description = "Names of the inline policies attached to the role"
  value       = [for k, v in aws_iam_role_policy.inline : v.name]
}

output "managed_policy_arns" {
  description = "ARNs of the managed policies attached to the role"
  value       = var.attach_aws_managed_policies ? var.managed_policy_arns : []
}

# ======================================================
# STANDALONE POLICY OUTPUTS
# ======================================================

output "standalone_policy_names" {
  description = "Names of the standalone customer-managed policies"
  value       = [for k, v in aws_iam_policy.standalone : v.name]
}

output "standalone_policy_arns" {
  description = "ARNs of the standalone customer-managed policies"
  value       = [for k, v in aws_iam_policy.standalone : v.arn]
}
