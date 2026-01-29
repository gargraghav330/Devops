terraform {
  backend "s3" {                                       # S3 as the remote backend
    bucket       = "terraform-state-bucket"            # S3 bucket name
    key          = "ecs-cluster/dev/terraform.tfstate" # Path within the bucket
    region       = "eu-central-1"                      # AWS region
    encrypt      = true                                # Enable encryption using DynamoDB for state locking
    use_lockfile = true                                # S3 State Locking
  }
}
