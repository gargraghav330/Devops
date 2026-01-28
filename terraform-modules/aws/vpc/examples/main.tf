# example.tf
provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../"

  # VPC and Subnet Configuration
  aws_region             = "us-east-1"
  vpc_cidr               = "172.31.0.0/16"  # AWS default VPC CIDR
  name_prefix            = "example"

  # Public subnets (default VPC has two public subnets)
  enable_public_subnets  = true
  public_subnet_cidrs    = ["172.31.0.0/20", "172.31.16.0/20"]

  # Private and intra subnets are not present in default VPC
  enable_private_subnets = false
  private_subnet_cidrs   = []
  enable_intra_subnets   = false
  intra_subnet_cidrs     = []

  # Internet Gateway is attached by default
  enable_internet_gateway = true

  # No NAT Gateway or VPC endpoints by default
  enable_nat_gateway        = false
  enable_s3_endpoint       = false
  enable_dynamodb_endpoint = false

  # Flow logs, NACLs, and custom security groups are not enabled by default
  enable_flow_logs     = false
  enable_network_acls  = false
  nacl_rules_per_subnet = {}

  # Default security group rules (allow all outbound, all inbound from self)
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

  tags = {
    Environment = "dev"
    Owner       = "example-team"
  }
}
