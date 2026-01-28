# AWS VPC Module

This Terraform module provisions a customizable AWS Virtual Private Cloud (VPC) with public, private, and intra (internal-only) subnets, an Internet Gateway, NAT Gateways, VPC endpoints (S3, DynamoDB), flow logs, Network ACLs (NACLs), and security groups. It is designed for multi-environment deployments (e.g., development, production) and supports use cases like hosting MongoDB in intra subnets with secure access to S3 and DynamoDB.

## Features

- **VPC Creation**: Provisions a VPC with a specified CIDR block.
- **Subnets**:
  - Public subnets with auto-assigned public IPs and Internet Gateway access.
  - Private subnets with optional NAT Gateway for outbound traffic.
  - Intra subnets for internal-only resources (e.g., MongoDB).
- **NAT Gateways**:
  - Dynamically provisions NAT Gateways based on private subnet count:
    - **1 NAT Gateway** if the number of private subnets is less than the number of Availability Zones (AZs).
    - **One NAT Gateway per AZ** if the number of private subnets equals or exceeds the number of AZs.
- **VPC Endpoints**: Gateway endpoints for S3 and DynamoDB to reduce costs and improve security.
- **Flow Logs**: Configurable to CloudWatch Logs or S3 with least-privilege IAM roles.
- **Network ACLs (NACLs)**: Customizable per-subnet rules for stateless traffic control (e.g., MongoDB port 27017).
- **Security Groups**: Stateful rules for application and database resources (e.g., HTTP, HTTPS, MongoDB).
- **Tagging**: Consistent tagging with `name_prefix` and custom tags for all resources.

## Prerequisites

- **Terraform**: Version 1.5.0 or higher.
- **AWS Provider**: Version 5.44.0.
- **AWS Credentials**: Configured with permissions to create VPCs, subnets, NAT Gateways, VPC endpoints, IAM roles, CloudWatch Logs, S3 buckets, NACLs, and security groups.


## Usage

1. **Add the Module** to your environment (e.g., `envs/project/dev/main.tf`):

```hcl
provider "aws" {
  region = "us-east-1" # This matches the default for aws_region
}

module "vpc" {
  source = "../../../modules/aws/vpc"

  aws_region  = "us-east-1"
  vpc_cidr    = "172.31.0.0/16"
  name_prefix = "default"

  enable_public_subnets      = true
  public_subnet_cidrs        = ["172.31.0.0/20", "172.31.16.0/20"]
  enable_private_subnets     = false
  private_subnet_cidrs       = []
  enable_intra_subnets       = false
  intra_subnet_cidrs         = []
  enable_internet_gateway    = true
  enable_nat_gateway         = false
  enable_s3_endpoint         = false
  enable_dynamodb_endpoint   = false
  enable_flow_logs           = false
  flow_log_destination_type  = "cloud-watch-logs"
  flow_log_log_group_name    = "vpc-flow-logs"
  flow_log_log_retention_days = 7
  flow_log_traffic_type      = "ALL"
  enable_network_acls        = false
  nacl_rules_per_subnet      = {}
  create_security_group      = true
  sg_ingress_rules           = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  sg_egress_rules            = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {}
}

```

2. **Configure Variables** in `terraform.tfvars` (e.g., `envs/project/dev/terraform.tfvars`):

```hcl
# terraform.tfvars

# 1. VPC Configuration
aws_region  = "us-east-1"
vpc_cidr    = "172.31.0.0/16"

# 2. Subnet Configuration
enable_public_subnets   = true
public_subnet_cidrs     = ["172.31.0.0/20", "172.31.16.0/20"]

enable_private_subnets  = false
private_subnet_cidrs    = []

enable_intra_subnets    = false
intra_subnet_cidrs      = []

# 3. Internet Gateway & NAT Gateway
enable_internet_gateway = true
enable_nat_gateway      = false

# 4. VPC Endpoints
enable_s3_endpoint       = false
enable_dynamodb_endpoint = false

# 5. Flow Logs
enable_flow_logs            = false
flow_log_destination_type   = "cloud-watch-logs"
flow_log_log_group_name     = "vpc-flow-logs"
flow_log_log_retention_days = 7
flow_log_traffic_type       = "ALL"

# 6. Network ACLs
enable_network_acls   = false
nacl_rules_per_subnet = {}

# 7. Naming and Tags
name_prefix = "default"
tags = {}

# 8. Security Group Rules (Optional)
create_security_group = true

sg_ingress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

sg_egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

```

3. **Create a backend.tf file in your environment**:

4. **Apply the Configuration**:

```bash
cd envs/project/dev
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.vpc_flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.nacl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_association.nacl_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.flow_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.flow_logs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_versioning.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_availability_zones.vpc_region_azs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.flow_log_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_log_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

The following variables are defined in `variables.tf`:

| Name                          | Description                                           | Type              | Default                       |
|-------------------------------|-------------------------------------------------------|-------------------|-------------------------------|
| `aws_region`                  | AWS region for resources                              | `string`          | `"us-west-1"`                 |
| `vpc_cidr`                    | CIDR block for the VPC                                | `string`          | `"10.0.0.0/16"`               |
| `enable_public_subnets`       | Enable public subnets                                  | `bool`            | `true`                        |
| `public_subnet_cidrs`         | CIDR blocks for public subnets                        | `list(string)`    | `["10.0.0.0/20"]`             |
| `enable_private_subnets`      | Enable private subnets                                 | `bool`            | `true`                        |
| `private_subnet_cidrs`        | CIDR blocks for private subnets                       | `list(string)`    | `["10.0.48.0/20"]`            |
| `enable_intra_subnets`        | Enable intra subnets (no internet access)              | `bool`            | `true`                        |
| `intra_subnet_cidrs`          | CIDR blocks for intra subnets                         | `list(string)`    | `["10.0.96.0/21"]`            |
| `enable_internet_gateway`     | Enable Internet Gateway                               | `bool`            | `true`                        |
| `enable_nat_gateway`          | Enable NAT Gateway(s)                                 | `bool`            | `true`                        |
| `enable_s3_endpoint`          | Enable S3 VPC endpoint                                | `bool`            | `true`                        |
| `enable_dynamodb_endpoint`    | Enable DynamoDB VPC endpoint                          | `bool`            | `true`                        |
| `enable_flow_logs`            | Enable VPC flow logs                                  | `bool`            | `true`                        |
| `flow_log_destination_type`   | Flow logs destination: `cloud-watch-logs` or `s3`     | `string`          | `"s3"`                        |
| `flow_log_log_group_name`     | CloudWatch Log Group name                             | `string`          | `"vpc-flow-logs"`             |
| `flow_log_log_retention_days` | Retention period for CloudWatch logs                  | `number`          | `14`                          |
| `flow_log_traffic_type`       | Traffic to log: `ACCEPT`, `REJECT`, or `ALL`          | `string`          | `"ALL"`                       |
| `enable_network_acls`         | Enable custom NACLs                                   | `bool`            | `true`                        |
| `nacl_rules_per_subnet`       | NACL rules per subnet                                 | `map(object)`     | See `variables.tf` for defaults |
| `create_security_group`       | Create security group with custom rules               | `bool`            | `true`                        |
| `sg_ingress_rules`            | Security group ingress rules                          | `list(object)`    | See `variables.tf` for defaults |
| `sg_egress_rules`             | Security group egress rules                           | `list(object)`    | See `variables.tf` for defaults |
| `name_prefix`                 | Prefix for resource names                             | `string`          | `"stage"`                     |
| `tags`                        | Custom tags for all resources                         | `map(string)`     | `{}`                          |

## Outputs

The following outputs are defined in `outputs.tf`:

| Name                    | Description                           |
|-------------------------|---------------------------------------|
| `vpc_id`                | ID of the VPC                         |
| `vpc_cidr_block`        | CIDR block of the VPC                 |
| `public_subnet_ids`     | List of public subnet IDs             |
| `private_subnet_ids`    | List of private subnet IDs            |
| `intra_subnet_ids`      | List of intra subnet IDs              |
| `public_route_table_id` | ID of the public route table          |
| `private_route_table_ids`| List of private route table IDs       |
| `intra_route_table_ids` | List of intra route table IDs         |
| `nat_gateway_ids`       | List of NAT Gateway IDs               |
| `vpc_endpoint_ids`      | Map of VPC endpoint IDs by service    |

## NAT Gateway Logic

- If `enable_nat_gateway = true`:
  - Creates **1 NAT Gateway** if the number of private subnets (`length(var.private_subnet_cidrs)`) is less than the number of AZs (`length(local.az_names)`).
  - Creates **one NAT Gateway per AZ** if the number of private subnets is equal to or greater than the number of AZs.
- Ensure `length(var.public_subnet_cidrs)` is sufficient for the number of NAT Gateways (e.g., at least 3 public subnets for 3 AZs).

## Example Scenarios

- **2 Private Subnets in us-west-1 (3 AZs)**:
  - `private_subnet_cidrs = ["10.0.48.0/20", "10.0.64.0/20"]`
  - Creates **1 NAT Gateway** in the first public subnet.
  - All private subnets route to this NAT Gateway.

- **3 Private Subnets in us-west-1 (3 AZs)**:
  - `private_subnet_cidrs = ["10.0.48.0/20", "10.0.64.0/20", "10.0.88.0/21"]`
  - Creates **3 NAT Gateways**, one per AZ.
  - Each private subnet routes to the NAT Gateway in its AZ.

## Notes
- Empty flow log bucket before destroying resource using Terraform.
- **S3 Flow Logs**: If `flow_log_destination_type = "s3"`, the module creates a bucket (`${var.name_prefix}-flow-logs-${account_id}`).

- **Cost Considerations**:
  - Single NAT Gateway: ~$0.045/hour.
  - One NAT Gateway per AZ: ~$0.045/hour * number of AZs (e.g., $0.135/hour for 3 AZs).
  - Use single NAT for dev environments to save costs.
- **Security Group Defaults**: The default `sg_ingress_rules` and `sg_egress_rules` allow all traffic (`0.0.0.0/0`, all ports). Override with restrictive rules for production environments.

## Testing

1. **Apply the module**:

```bash
cd envs/project/dev
terraform init
terraform apply -var-file=terraform.tfvars
```

2. **Verify resources**:

```bash
# Check VPC
aws ec2 describe-vpcs --filters Name=tag:Name,Values=default-vpc

# Check subnets
aws ec2 describe-subnets --filters Name=tag:Name,Values=default-\*

# Check flow logs (CloudWatch)
aws logs describe-log-groups --log-group-name-prefix vpc-flow-logs-default
