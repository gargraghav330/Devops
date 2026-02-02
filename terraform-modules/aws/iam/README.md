# AWS IAM Roles and Policies Terraform Module

This Terraform module creates and manages AWS IAM roles, inline policies, managed policy attachments, and standalone customer-managed policies. It supports flexible configuration for trust policies, including cross-account access with External IDs, and adheres to AWS best practices for security and compliance.

## Features
- **IAM Role Creation**: Conditionally creates an IAM role with customizable trust policy, description, session duration, and permissions boundary.
- **Inline Policies**: Attaches custom policies to the role, with conditional creation.
- **Managed Policy Attachments**: Attaches AWS or customer-managed policies to the role.
- **Standalone Policies**: Creates customer-managed policies not attached to any role, for use by other entities.
- **Unique Naming**: Generates unique role and policy names using prefixes, environment, and random suffixes.
- **Tagging**: Applies consistent tags for organization and cost tracking.
- **Logging**: Supports CloudTrail logging for compliance (assumes external CloudTrail configuration).

## Requirements
- Terraform >= 1.0
- AWS Provider >= 5.44.0
- Random Provider >= 3.5.1

## Usage

### Minimal Configuration
Creates an IAM role with a default trust policy and a standalone policy.

```hcl
module "iam_minimal" {
  source = "./modules/aws/iam"

  create_iam_role = true
  role_name_prefix = "app"
  environment = "dev"

  standalone_policies = [
    {
      policy = {
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:ListBucket"]
            Resource = ["arn:aws:s3:::my-bucket"]
          }
        ]
      }
      description = "Standalone S3 list policy"
    }
  ]
}
```

### Comprehensive Configuration
Creates an IAM role with a custom trust policy, inline policies, managed policies, standalone policies, and tags.

```hcl
module "iam_comprehensive" {
  source = "./modules/aws/iam"

  create_iam_role            = true
  create_inline_policies     = true
  attach_aws_managed_policies = true
  role_name_prefix           = "my-app"
  policy_name_prefix         = "my-app-policy"
  environment                = "prod"
  role_description           = "IAM role for MyApp in production"

  principal_type      = "Service"
  principal_identifier = "ec2.amazonaws.com"
  external_id         = "app-id-1234"

  max_session_duration      = 7200
  permissions_boundary_arn   = "arn:aws:iam::123456789012:policy/MyBoundaryPolicy"

  inline_policies = [
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:ListBucket"]
          Resource = ["arn:aws:s3:::my-app-bucket/*"]
        }
      ]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]

  standalone_policies = [
    {
      policy = {
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:PutObject"]
            Resource = ["arn:aws:s3:::my-app-bucket/*"]
          }
        ]
      }
      description = "Standalone S3 put policy"
    }
  ]

  tags = {
    Project = "MyApp"
    Owner   = "DevOpsTeam"
  }

  enable_logging = true
}
```

## Cross-Account Role with External ID
Creates a role for cross-account access with an External ID.

```hcl
module "iam_cross_account" {
  source = "./modules/aws/iam"

  create_iam_role  = true
  role_name_prefix = "cross-account"
  environment      = "prod"

  principal_type      = "AWS"
  principal_identifier = "arn:aws:iam::123456789012:root"
  external_id         = "unique-id-1234"

  inline_policies = [
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject"]
          Resource = ["arn:aws:s3:::shared-bucket/*"]
        }
      ]
    }
  ]
}
```

## Inputs

| Name                       | Description                                                                 | Type                  | Default                              |
|----------------------------|-----------------------------------------------------------------------------|-----------------------|--------------------------------------|
| create_iam_role            | Whether to create the IAM role                                              | bool                  | `true`                               |
| create_inline_policies     | Whether to create inline policies for the IAM role                          | bool                  | `true`                               |
| attach_aws_managed_policies | Whether to attach managed policies to the IAM role                          | bool                  | `true`                              |
| role_name_prefix           | Prefix for the IAM role name (combined with environment and random suffix)   | string                | `"generic-role"`                    |
| policy_name_prefix         | Prefix for standalone IAM policy names (combined with environment and index) | string                | `null`                              |
| environment                | Deployment environment (e.g., dev, staging, prod)                            | string                | `"dev"`                             |
| role_description           | Description for the IAM role                                                | string                | `null`                               |
| assume_role_policy         | JSON policy document for the assume role trust relationship                  | string                | `null`                              |
| principal_type             | Type of principal for the default trust policy (e.g., Service, AWS)         | string                | `null`                               |
| principal_identifier       | Identifier for the principal (e.g., ec2.amazonaws.com, ARN)                 | string                | `null`                               |
| external_id                | External ID for the assume role policy (for cross-account trust)            | string                | `null`                               |
| max_session_duration       | Maximum session duration for the role in seconds (3600 to 43200)            | number                | `null`                               |
| permissions_boundary_arn   | ARN of the permissions boundary policy to apply to the role                 | string                | `null`                               |
| inline_policies            | List of inline policy documents (JSON objects) to attach to the role        | list(map(any))        | `[]`                                 |
| managed_policy_arns        | List of managed policy ARNs to attach to the role                           | list(string)          | `[]`                                 |
| standalone_policies        | List of standalone customer-managed policy documents (JSON objects)         | list(object)          | `[]`                                 |
| tags                       | Additional tags to apply to resources                                       | map(string)           | `{}`                                 |
| enable_logging             | Enable logging for IAM actions via CloudTrail (assumes CloudTrail setup)    | bool                  | `true`                               |

## Outputs

| Name                     | Description                                          |
|--------------------------|------------------------------------------------------|
| role_name                | Name of the created IAM role                         |
| role_arn                 | ARN of the created IAM role                          |
| inline_policy_names      | Names of the inline policies attached to the role    |
| managed_policy_arns      | ARNs of the managed policies attached to the role    |
| standalone_policy_names  | Names of the standalone customer-managed policies    |
| standalone_policy_arns   | ARNs of the standalone customer-managed policies     |

## Notes
- Ensure valid JSON for `assume_role_policy` and policy documents in `inline_policies` and `standalone_policies`.
- Replace placeholder ARNs and bucket names in examples with your own values.
- Role names must be ≤ 64 characters, enforced by `locals.tf`.
