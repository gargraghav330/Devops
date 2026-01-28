# ===========================
# File: outputs.tf
# Description: Defines outputs for the root module to expose VPC, subnet, NAT, and logging information.
# ===========================

# Basic network information
#
# - Summarizes VPC name, subnets, NAT gateways, and logging configuration.
output "basic_network_info" {
  description = "Basic information about VPC, subnets, NAT gateways, and logging configuration."
  value = {
    for vpc in var.vpcs : vpc.network_name => {
      vpc = {
        name                = vpc.network_name
        project_id          = var.project_id
        routing_mode        = vpc.routing_mode
        auto_create_subnets = vpc.auto_create_subnetworks
        ipv6_enabled        = vpc.enable_ipv6
        mtu                 = vpc.mtu != null ? vpc.mtu : 1460
        bgp_best_path       = vpc.best_path_selection_mode != null ? vpc.best_path_selection_mode : "LEGACY"
        vpc_id              = module.vpc[vpc.network_name].vpc_id
        vpc_self_link       = module.vpc[vpc.network_name].vpc_self_link
      }
      public_subnets = [
        for subnet in vpc.public_subnets : {
          name                  = subnet.name
          cidr                  = subnet.cidr
          region                = subnet.region
          network_tags          = subnet.network_tags
          secondary_ranges      = subnet.secondary_ranges
          private_google_access = false
          subnet_id             = module.vpc[vpc.network_name].public_subnet_ids[subnet.name]
          subnet_self_link      = module.vpc[vpc.network_name].public_subnet_self_links[subnet.name]
        }
      ]
      private_subnets = [
        for subnet in vpc.private_subnets : {
          name                  = subnet.name
          cidr                  = subnet.cidr
          region                = subnet.region
          network_tags          = subnet.network_tags
          secondary_ranges      = subnet.secondary_ranges
          private_google_access = true
          subnet_id             = module.vpc[vpc.network_name].private_subnet_ids[subnet.name]
          subnet_self_link      = module.vpc[vpc.network_name].private_subnet_self_links[subnet.name]
        }
      ]
      nat_gateways = vpc.enable_nat ? [
        for region in distinct([for subnet in vpc.private_subnets : subnet.region]) : {
          name            = "${vpc.network_name}-nat-${region}"
          region          = region
          router_name     = "${vpc.network_name}-nat-router-${region}"
          ip_allocation   = vpc.nat_config.nat_ip_allocate_option
          subnetworks     = [for subnet in vpc.private_subnets : subnet.name if subnet.region == region]
          nat_id          = module.vpc[vpc.network_name].nat_ids[region]
          logging_enabled = vpc.nat_config.enable_logging
        }
      ] : []
      logging = {
        enabled              = vpc.enable_logging
        destination          = vpc.cloud_logging_enabled ? "Cloud Logging" : "Cloud Storage Bucket (${vpc.network_name}-logs-${var.project_id})"
        retention_period     = vpc.log_config.retention_period / 86400 # Convert seconds to days
        cmek_enabled         = vpc.enable_cmek
        aggregation_interval = vpc.log_config.aggregation_interval
        flow_sampling        = vpc.log_config.flow_sampling
        metadata             = vpc.log_config.metadata
      }
    }
  }
}
