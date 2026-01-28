########################
# Provider & Data Sources
########################

provider "aws" {
  alias  = "resource-region"
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "vpc_region_azs" {
  state = "available"
}

########################
# VPC
########################

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-vpc"
  })

  # Ignore tag drift for smoother management
  lifecycle {
    ignore_changes = [tags]
  }
}

########################
# Internet Gateway
########################

resource "aws_internet_gateway" "internet_gateway" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-igw"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

########################
# Subnets
########################

# Public Subnets
resource "aws_subnet" "public" {
  count                   = var.enable_public_subnets ? length(var.public_subnet_cidrs) : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(local.az_names, count.index % length(local.az_names))
  map_public_ip_on_launch = true

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-public-${element(local.az_names, count.index % length(local.az_names))}-${count.index + 1}"
    Tier = "public"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = var.enable_private_subnets ? length(var.private_subnet_cidrs) : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = element(local.az_names, count.index % length(local.az_names))
  map_public_ip_on_launch = false

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-private-${element(local.az_names, count.index % length(local.az_names))}-${count.index + 1}"
    Tier = "private"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Intra (internal-only) Subnets
resource "aws_subnet" "intra" {
  count             = var.enable_intra_subnets ? length(var.intra_subnet_cidrs) : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.intra_subnet_cidrs[count.index]
  availability_zone = element(local.az_names, count.index % length(local.az_names))

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-intra-${element(local.az_names, count.index % length(local.az_names))}-${count.index + 1}"
    Tier = "intra"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

########################
# NAT Gateway
########################

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (local.use_single_nat_gateway ? 1 : length(local.az_names)) : 0

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index}"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateway" {
  count         = var.enable_nat_gateway ? (local.use_single_nat_gateway ? 1 : length(local.az_names)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-nat-${count.index}"
  })

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [aws_internet_gateway.internet_gateway, aws_eip.nat]
}

########################
# Route Tables & Associations
########################

# Public Route Table
resource "aws_route_table" "public" {
  count  = var.enable_public_subnets && var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-public-rt"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Public Route to Internet
resource "aws_route" "public_internet" {
  count                  = var.enable_public_subnets && var.enable_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway[0].id
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = var.enable_public_subnets ? length(var.public_subnet_cidrs) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Tables (one per private subnet)
resource "aws_route_table" "private" {
  count  = var.enable_private_subnets ? length(var.private_subnet_cidrs) : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-private-rt-${count.index}"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Private Route to NAT Gateway
resource "aws_route" "private_nat" {
  count                  = var.enable_private_subnets && var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.use_single_nat_gateway ? aws_nat_gateway.nat_gateway[0].id : aws_nat_gateway.nat_gateway[count.index % length(aws_nat_gateway.nat_gateway)].id
}

# Associate Private Subnets with Private Route Tables
resource "aws_route_table_association" "private" {
  count          = var.enable_private_subnets ? length(var.private_subnet_cidrs) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Intra Route Tables (one per intra subnet)
resource "aws_route_table" "intra" {
  count  = var.enable_intra_subnets ? length(var.intra_subnet_cidrs) : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-intra-rt-${count.index}"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Associate Intra Subnets with Intra Route Tables
resource "aws_route_table_association" "intra" {
  count          = var.enable_intra_subnets ? length(var.intra_subnet_cidrs) : 0
  subnet_id      = aws_subnet.intra[count.index].id
  route_table_id = aws_route_table.intra[count.index].id
}

########################
# VPC Endpoints
########################

# Generic VPC Endpoints (supports Gateway type)
resource "aws_vpc_endpoint" "this" {
  for_each = { for k, v in local.endpoint_configs : k => v if v.enabled }

  vpc_id              = aws_vpc.vpc.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.type
  route_table_ids     = each.value.route_table_ids
  private_dns_enabled = each.value.private_dns_enabled

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-${each.key}-endpoint"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

########################
# Flow Logs
########################

# CloudWatch Log Group for Flow Logs (if using CloudWatch)
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  count             = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name              = "${var.flow_log_log_group_name}-${var.name_prefix}"
  retention_in_days = var.flow_log_log_retention_days

  tags = merge(var.tags, local.default_tags)

  lifecycle {
    ignore_changes = [tags]
  }
  depends_on = [aws_iam_role_policy.flow_log]
}

# IAM Role for Flow Logs (if using CloudWatch)
data "aws_iam_policy_document" "flow_log_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log" {
  count              = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name               = "${var.name_prefix}-vpc-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json
}

data "aws_iam_policy_document" "flow_log_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.flow_log_log_group_name}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.flow_log_log_group_name}:log-stream:*"
    ]
  }
}

resource "aws_iam_role_policy" "flow_log" {
  count  = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name   = "${var.name_prefix}-vpc-flow-log-policy"
  role   = aws_iam_role.flow_log[0].id
  policy = data.aws_iam_policy_document.flow_log_permissions.json
}

# S3 Bucket for Flow Logs (if using S3)
resource "aws_s3_bucket" "flow_logs_bucket" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0

  bucket = "${var.name_prefix}-flow-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-flow-logs"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# S3 Bucket Policy for Flow Logs
resource "aws_s3_bucket_policy" "flow_logs_bucket_policy" {
  count  = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_bucket[0].id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowVPCAccessToS3Logs",
        "Effect": "Allow",
        "Principal": {
          "Service": "vpc-flow-logs.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.flow_logs_bucket[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      },
      {
        "Sid": "AllowVPCAccessGetBucketACL",
        "Effect": "Allow",
        "Principal": {
          "Service": "vpc-flow-logs.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "${aws_s3_bucket.flow_logs_bucket[0].arn}"
      },
      {
        "Sid": "AWSLogDeliveryWrite",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.flow_logs_bucket[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}",
            "s3:x-amz-acl": "bucket-owner-full-control"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        "Sid": "AWSLogDeliveryAclCheck",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "${aws_s3_bucket.flow_logs_bucket[0].arn}",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

# S3 Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "flow_logs" {
  count  = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_bucket[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket ACL
resource "aws_s3_bucket_acl" "flow_logs" {
  count      = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket     = aws_s3_bucket.flow_logs_bucket[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.flow_logs]
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "flow_logs" {
  count  = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# VPC Flow Log Resource
resource "aws_flow_log" "vpc_flow_log" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.vpc.id
  max_aggregation_interval = 60
  traffic_type         = var.flow_log_traffic_type
  log_destination_type = var.flow_log_destination_type
  log_destination      = var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.cloudwatch_log_group[0].arn : aws_s3_bucket.flow_logs_bucket[0].arn
  iam_role_arn         = var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-vpc-flow-log"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

########################
# Network ACLs
########################

# Network ACLs per subnet
resource "aws_network_acl" "nacl" {
  for_each = var.enable_network_acls ? local.all_subnets : {}

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-${each.key}-nacl"
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Associate NACLs with subnets
resource "aws_network_acl_association" "nacl_assoc" {
  for_each = var.enable_network_acls ? local.all_subnets : {}

  subnet_id      = each.value
  network_acl_id = aws_network_acl.nacl[each.key].id
}

# Ingress NACL Rules
resource "aws_network_acl_rule" "ingress" {
  for_each = local.nacl_ingress_rules

  network_acl_id = aws_network_acl.nacl[each.value.subnet_key].id
  rule_number    = each.value.rule.rule_no
  protocol       = each.value.rule.protocol
  rule_action    = each.value.rule.rule_action
  cidr_block     = each.value.rule.cidr_block
  from_port      = each.value.rule.from_port
  to_port        = each.value.rule.to_port
  egress         = false
}

# Egress NACL Rules
resource "aws_network_acl_rule" "egress" {
  for_each = local.nacl_egress_rules

  network_acl_id = aws_network_acl.nacl[each.value.subnet_key].id
  rule_number    = each.value.rule.rule_no
  protocol       = each.value.rule.protocol
  rule_action    = each.value.rule.rule_action
  cidr_block     = each.value.rule.cidr_block
  from_port      = each.value.rule.from_port
  to_port        = each.value.rule.to_port
  egress         = true
}

########################
# Security Groups
########################

resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name_prefix = var.name_prefix
  vpc_id      = aws_vpc.vpc.id

  tags = merge(var.tags, local.default_tags, {
    Name = "${var.name_prefix}-security-group"
  })
}

# Ingress Security Group Rules
resource "aws_security_group_rule" "ingress" {
  for_each = var.create_security_group ? {
    for rule in var.sg_ingress_rules :
    "${rule.protocol}-${rule.from_port}-${rule.to_port}-${join(",", rule.cidr_blocks)}" => rule
  } : {}

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.this[0].id
}

# Egress Security Group Rules
resource "aws_security_group_rule" "egress" {
  for_each = var.create_security_group ? {
    for rule in var.sg_egress_rules :
    "${rule.protocol}-${rule.from_port}-${rule.to_port}-${join(",", rule.cidr_blocks)}" => rule
  } : {}

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.this[0].id
}
