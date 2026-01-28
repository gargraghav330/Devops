############################
# Default Tags
############################
locals {
  default_tags = {
    Environment = var.name_prefix
    ManagedBy   = "Terraform"
  }
}

############################
# Availability Zone Names
############################
locals {
  az_names = data.aws_availability_zones.vpc_region_azs.names
}

############################
# Single NAT Gateway Flag
############################
locals {
  use_single_nat_gateway = var.enable_nat_gateway && length(var.private_subnet_cidrs) < length(local.az_names)
}

############################
# All Subnets Map (by tier and index)
# This is used for NACL associations and other subnet-wide operations
############################
locals {
  all_subnets = merge(
    { for idx, id in aws_subnet.public[*].id  : "public-${idx}"  => id if var.enable_public_subnets  },
    { for idx, id in aws_subnet.private[*].id : "private-${idx}" => id if var.enable_private_subnets },
    { for idx, id in aws_subnet.intra[*].id   : "intra-${idx}"   => id if var.enable_intra_subnets   }
  )
}

############################
# VPC Endpoint Configurations
# These determine what endpoints to create based on feature flags
############################
locals {
  endpoint_configs = {
    s3 = {
      service_name        = "com.amazonaws.${var.aws_region}.s3"
      type                = "Gateway"
      enabled             = var.enable_s3_endpoint
      route_table_ids     = concat(
        var.enable_intra_subnets   ? aws_route_table.intra[*].id   : [],
        var.enable_private_subnets ? aws_route_table.private[*].id : []
      )
      private_dns_enabled = false
    },

    dynamodb = {
      service_name        = "com.amazonaws.${var.aws_region}.dynamodb"
      type                = "Gateway"
      enabled             = var.enable_dynamodb_endpoint
      route_table_ids     = concat(
        var.enable_intra_subnets   ? aws_route_table.intra[*].id   : [],
        var.enable_private_subnets ? aws_route_table.private[*].id : []
      )
      private_dns_enabled = false
    }
  }
}

############################
# NACL Rules (Ingress)
# Flattened per-subnet rule map for ingress
############################
locals {
  nacl_ingress_rules = {
    for rule in flatten([
      for subnet_key, block in var.nacl_rules_per_subnet : [
        for rule in block.ingress : {
          subnet_key = subnet_key
          rule       = rule
          key        = "${subnet_key}-ingress-${rule.rule_no}"
        }
      ]
    ]) :
    rule.key => {
      subnet_key = rule.subnet_key
      rule       = rule.rule
    }
    if var.enable_network_acls && contains(keys(local.all_subnets), rule.subnet_key)
  }
}

############################
# NACL Rules (Egress)
# Flattened per-subnet rule map for egress
############################
locals {
  nacl_egress_rules = {
    for rule in flatten([
      for subnet_key, block in var.nacl_rules_per_subnet : [
        for rule in block.egress : {
          subnet_key = subnet_key
          rule       = rule
          key        = "${subnet_key}-egress-${rule.rule_no}"
        }
      ]
    ]) :
    rule.key => {
      subnet_key = rule.subnet_key
      rule       = rule.rule
    }
    if var.enable_network_acls && contains(keys(local.all_subnets), rule.subnet_key)
  }
}
