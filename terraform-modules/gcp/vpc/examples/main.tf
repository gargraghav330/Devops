# ===========================
# File: main.tf
# Description: Root module for creating VPCs using the VPC module.
# ===========================

# VPC Module
# - Creates one VPC per configuration in `var.vpcs`.
# - Configures subnets, NAT, firewall rules, and logging based on input variables.
module "vpc" {
  source                   = "../"
  for_each                 = { for vpc in var.vpcs : vpc.network_name => vpc }
  service_account_email    = var.service_account_email
  project_id               = var.project_id
  network_name             = each.value.network_name
  auto_create_subnetworks  = each.value.auto_create_subnetworks
  routing_mode             = each.value.routing_mode
  enable_ipv6              = each.value.enable_ipv6
  vpc_mtu                  = each.value.mtu
  enable_logging           = each.value.enable_logging
  cloud_logging_enabled    = each.value.cloud_logging_enabled
  enable_cmek              = each.value.enable_cmek
  log_config               = each.value.log_config
  enable_nat               = each.value.enable_nat
  create_cloud_router      = each.value.create_cloud_router
  best_path_selection_mode = each.value.best_path_selection_mode
  cloud_router_config      = each.value.cloud_router_config
  nat_config               = each.value.nat_config
  public_subnets           = each.value.public_subnets
  private_subnets          = each.value.private_subnets
  firewall_rules           = each.value.firewall_rules
}
