#############################################
# 1. VPC Configuration
#############################################

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9]$", var.aws_region))
    error_message = "Must be a valid AWS region (e.g., us-east-1)"
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "172.31.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Must be a valid IPv4 CIDR block (e.g., 172.31.0.0/16)"
  }
}

#############################################
# 2. Subnet Configuration
#############################################

variable "enable_public_subnets" {
  description = "Enable creation of public subnets"
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.31.0.0/20", "172.31.16.0/20"]

  validation {
    condition     = var.enable_public_subnets == false || alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks when public subnets are enabled"
  }

  validation {
    condition     = var.enable_public_subnets == false || length(var.public_subnet_cidrs) > 0
    error_message = "Provide at least one CIDR for public subnets if public subnets are enabled"
  }
}

variable "enable_private_subnets" {
  description = "Enable creation of private subnets"
  type        = bool
  default     = false
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_private_subnets == false || alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks when private subnets are enabled"
  }

  validation {
    condition     = var.enable_private_subnets == false || length(var.private_subnet_cidrs) > 0
    error_message = "Provide at least one CIDR for private subnets if private subnets are enabled"
  }
}

variable "enable_intra_subnets" {
  description = "Enable creation of intra subnets (no internet access)"
  type        = bool
  default     = false
}

variable "intra_subnet_cidrs" {
  description = "List of CIDR blocks for intra subnets"
  type        = list(string)
  default     = []

  validation {
    condition     = var.enable_intra_subnets == false || alltrue([for cidr in var.intra_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All intra subnet CIDRs must be valid IPv4 CIDR blocks when intra subnets are enabled"
  }

  validation {
    condition     = var.enable_intra_subnets == false || length(var.intra_subnet_cidrs) > 0
    error_message = "Provide at least one CIDR for intra subnets if intra subnets are enabled"
  }
}

#############################################
# 3. Internet Gateway & NAT Gateway
#############################################

variable "enable_internet_gateway" {
  description = "Enable creation of an Internet Gateway"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable creation of NAT Gateway(s)"
  type        = bool
  default     = false
}

#############################################
# 4. VPC Endpoints
#############################################

variable "enable_s3_endpoint" {
  description = "Enable creation of S3 VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Enable creation of DynamoDB VPC endpoint"
  type        = bool
  default     = false
}

#############################################
# 5. Flow Logs
#############################################

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "flow_log_destination_type" {
  description = "Type of destination for flow logs: cloud-watch-logs or s3"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_log_group_name" {
  description = "Name of the CloudWatch Log Group (required if using CloudWatch)"
  type        = string
  default     = "vpc-flow-logs"
}

variable "flow_log_log_retention_days" {
  description = "Retention period for CloudWatch logs"
  type        = number
  default     = 7
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to log: ACCEPT, REJECT, or ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], upper(var.flow_log_traffic_type))
    error_message = "flow_log_traffic_type must be one of: ACCEPT, REJECT, ALL"
  }
}

#############################################
# 6. Network ACLs
#############################################

variable "enable_network_acls" {
  description = "Enable creation of Network ACLs"
  type        = bool
  default     = false
}

variable "nacl_rules_per_subnet" {
  description = "Optional NACL rules mapped per subnet name"
  type = map(object({
    ingress = optional(list(object({
      rule_no     = number
      protocol    = string
      rule_action = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    })), [])
    egress = optional(list(object({
      rule_no     = number
      protocol    = string
      rule_action = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    })), [])
  }))
  default = {}
}

#############################################
# 7. Naming and Tags
#############################################

variable "name_prefix" {
  description = "Prefix to prepend to resource names"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#############################################
# 8. Security Group Rules (Optional)
#############################################

variable "create_security_group" {
  description = "Whether to create a security group"
  type        = bool
  default     = true
}

variable "sg_ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "sg_egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
