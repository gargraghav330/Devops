# Minimal Configuration
# Creates an IAM role with a default trust policy for EC2 and minimal settings
module "iam_minimal" {
  source = "../"

  create_iam_role  = true
  role_name_prefix = "app"
  environment      = "dev"

  principal_type       = "Service"
  principal_identifier = "ec2.amazonaws.com"

  tags = {
    Project = "MinimalApp"
  }
}

# Comprehensive Configuration
# Creates an IAM role with custom trust policy, inline and managed policies, standalone policies, and tags
module "iam_comprehensive" {
  source = "../"

  create_iam_role             = true
  create_inline_policies      = true
  attach_aws_managed_policies = true
  role_name_prefix            = "my-app"
  policy_name_prefix          = "my-app-policy"
  environment                 = "prod"
  role_description            = "IAM role for MyApp in production"
  max_session_duration        = 7200
  #   permissions_boundary_arn    = "arn:aws:iam::123456789012:policy/MyBoundaryPolicy"

  principal_type       = "Service"
  principal_identifier = "ec2.amazonaws.com"
  external_id          = "app-id-1234"

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
    },
    {
      policy = {
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:ListBucket"]
            Resource = ["arn:aws:s3:::my-app-bucket"]
          }
        ]
      }
      description = "Standalone S3 list policy"
    }
  ]

  tags = {
    Project     = "MyApp"
    Environment = "Production"
    Owner       = "DevOpsTeam"
  }

}

# Cross-Account Configuration
# Creates an IAM role for cross-account access with External ID, suitable for S3 access
module "iam_cross_account" {
  source = "../"

  create_iam_role  = true
  role_name_prefix = "cross-account"
  environment      = "prod"

  principal_type       = "AWS"
  principal_identifier = "arn:aws:iam::522814707398:root"
  external_id          = "unique-id-1234"

  inline_policies = [
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:ListBucket"]
          Resource = ["arn:aws:s3:::shared-bucket/*"]
        }
      ]
    }
  ]

  tags = {
    Project = "CrossAccount"
  }
}
