# ECS Deployment Examples

This directory (`examples/`) contains three complete, ready-to-run configurations using the parent ECS module:

- **fargate** – Simple, serverless Fargate-only cluster
- **ec2-awsvpc-mode** – Modern EC2 cluster using awsvpc networking
- **ec2-bridge-mode** – Legacy EC2 cluster using bridge networking

All examples use relative path `source = "../../"` to reference the module.

### Prerequisites

- Terraform ≥ 1.5.7
- AWS CLI configured with credentials
- SSH key uploaded to AWS EC2 (required for EC2 examples)
- Git access to private VPC module repo
  - Run: `ssh-add ~/.ssh/your_key` (add your SSH key)
- S3 backend for remote state (strongly recommended)

**S3 Setup** (one-time, outside Terraform)

```bash
# Create bucket
aws s3api create-bucket --bucket <bucket-name> --region <region>
**Shortest version (README-ready):**

```bash
# Enable S3 versioning (recommended)
aws s3api put-bucket-versioning --bucket <bucket> \
  --versioning-configuration Status=Enabled
```

> Use `use_lockfile` for state locking.

```

Add to root `backend.tf`:

```terraform
terraform {
  backend "s3" {
    bucket         = "<bucket-name>"
    key            = "ecs/<example>/terraform.tfstate"
    region         = "<region>"
    encrypt        = true
    use_lockfile   =  true
  }
}
```

### Setup & Deployment

1. **Navigate to the example directory**

   ```bash
   cd examples/fargate.          # or ec2-awsvpc-mode or ec2-bridge-mode
   ```

2. **Create or copy `terraform.tfvars`**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Initialize**

   ```bash
   terraform init
   ```

4. **Plan**

   ```bash
   terraform plan -var-file=terraform.tfvars
   ```

5. **Apply**

   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

   Type `yes` to confirm.

6. **Destroy** (cleanup)

   ```bash
   terraform destroy -var-file=terraform.tfvars
   ```

### Important Notes & Best Practices

- **Always use private subnets** for EC2 + awsvpc mode (no public IP allowed on tasks)
- **assign_public_ip = true** is safe only for Fargate (EC2 forbids it)
- Container definitions **must** be in JSON files – module auto-adds `awslogs` logging if missing
- Use **S3 backend + DynamoDB lock** in production to prevent state corruption
- Set `log_retention_days ≥ 90` for compliance & debugging
- Enable `enable_task_autoscaling = true` for production workloads
- EC2 examples: Use recent ECS-optimized AMI
