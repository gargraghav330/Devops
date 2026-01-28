# ===========================
# File: modules/vpc/main.tf
# Description: Creates a GCP VPC with custom subnets, Cloud NAT, firewall rules, and logging.
# ===========================

# Grant Custom Storage Role to the service account
# - Required if `cloud_logging_enabled = false` in `terraform.tfvars` to manage Cloud Storage logs.
# - Use `google_project_iam_member` instead of `binding` to avoid overwriting existing members.


# resource "google_project_iam_member" "service_account_storage_admin" {
#   project = var.project_id
#   role    = "projects/${var.project_id}/roles/CustomStorageRole"
#   member  = "serviceAccount:${var.service_account_email}"
# }

# Add delay for IAM propagation
# - Waits 60 seconds to ensure IAM roles are applied before creating VPC resources.
# resource "time_sleep" "wait_for_iam" {
#   depends_on      = [google_project_iam_member.service_account_storage_admin]
#   create_duration = "60s"
# }

# Create the VPC network
resource "google_compute_network" "vpc" {
  name = var.network_name
  # Set to `true` to auto-create subnets in each region.
  # Set to `false` to use custom subnets defined in `public_subnets` and `private_subnets`.
  auto_create_subnetworks = var.auto_create_subnetworks
  # Use `REGIONAL` for simpler routing within a region or `GLOBAL` for cross-region traffic (e.g., multi-region GKE).
  routing_mode = var.routing_mode
  project      = var.project_id
  description  = "Managed by Terraform - Custom VPC"
  # Enable IPv6 if required (e.g., for specific workloads).
  enable_ula_internal_ipv6 = var.enable_ipv6
  # Set custom MTU (default 1460) for performance tuning (e.g., 1500 for larger packets if supported).
  mtu = var.vpc_mtu != null ? var.vpc_mtu : 1460
  # Configure BGP path selection: `LEGACY` (default) or `STANDARD` (advanced routing). Leave null for default.
  bgp_best_path_selection_mode = var.best_path_selection_mode != null ? var.best_path_selection_mode : "LEGACY"
  lifecycle {
    # Ignore changes to description to prevent accidental updates.
    ignore_changes = [description]
  }
  # Ensure IAM roles are applied before creating VPC resources.
  # depends_on = [time_sleep.wait_for_iam]
}

# Public Subnets
# - Used for resources requiring public IPs (e.g., load balancers, bastion hosts).
# - Define in `public_subnets` with name, CIDR, region, network tags, and optional secondary ranges.
resource "google_compute_subnetwork" "public" {
  for_each      = var.auto_create_subnetworks ? {} : { for subnet in var.public_subnets : subnet.name => subnet }
  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  # Disable private Google access for public subnets (no direct access to internal GCP APIs without NAT).
  private_ip_google_access = false
  # Define secondary IP ranges (e.g., for GKE pods or services if used in public subnets).
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges != null ? each.value.secondary_ranges : []
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  # Enable flow logs if `enable_logging = true` for monitoring and debugging.
  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      aggregation_interval = var.log_config.aggregation_interval
      flow_sampling        = var.log_config.flow_sampling
      metadata             = var.log_config.metadata
    }
  }
}

# Private Subnets
# - Used for resources without public IPs (e.g., GKE nodes, VMs, databases).
# - Define in `private_subnets` with name, CIDR, region, network tags, and optional secondary ranges.
resource "google_compute_subnetwork" "private" {
  for_each      = var.auto_create_subnetworks ? {} : { for subnet in var.private_subnets : subnet.name => subnet }
  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  # Enable private Google access to allow access to GCP APIs (e.g., Cloud Storage, BigQuery) without public IPs.
  private_ip_google_access = true
  # Define secondary IP ranges (e.g., for GKE pods and services).
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges != null ? each.value.secondary_ranges : []
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  # Enable flow logs if `enable_logging = true` for monitoring and debugging.
  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      aggregation_interval = var.log_config.aggregation_interval
      flow_sampling        = var.log_config.flow_sampling
      metadata             = var.log_config.metadata
    }
  }
}

# Default Route for Internet Access
# - Routes all traffic (0.0.0.0/0) to the internet gateway for public subnets or NAT.
resource "google_compute_route" "default_internet" {
  name             = "${var.network_name}-default-internet"
  network          = google_compute_network.vpc.id
  project          = var.project_id
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}


# Default Cloud Router for NAT
# - Required if `enable_nat = true` to provide internet access for private subnets.
# - Creates one router per region where private subnets exist.
resource "google_compute_router" "nat_router_default" {
  for_each = var.enable_nat ? toset(distinct([for subnet in var.private_subnets : subnet.region])) : []
  name     = "${var.network_name}-nat-router-${each.key}"
  network  = google_compute_network.vpc.id
  region   = each.key
  project  = var.project_id
}

# Cloud NAT for private subnets
# - Allows private subnets to access the internet (e.g., for updates, external APIs) without public IPs.
# - Configure `nat_config` for IP allocation, port settings, and logging.
resource "google_compute_router_nat" "nat" {
  for_each = var.enable_nat ? toset(distinct([for subnet in var.private_subnets : subnet.region])) : []
  name     = "${var.network_name}-nat-${each.key}"
  router   = google_compute_router.nat_router_default[each.key].name
  region   = each.key
  project  = var.project_id
  # Set to `AUTO_ONLY` for automatic IP allocation or `MANUAL_ONLY` to specify IPs in `nat_config.nat_ips`.
  nat_ip_allocate_option              = var.nat_config.nat_ip_allocate_option
  nat_ips                             = var.nat_config.nat_ip_allocate_option == "MANUAL_ONLY" ? var.nat_config.nat_ips : []
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
  min_ports_per_vm                    = var.nat_config.min_ports_per_vm
  max_ports_per_vm                    = var.nat_config.max_ports_per_vm
  enable_endpoint_independent_mapping = var.nat_config.enable_endpoint_independent_mapping
  # Map private subnets to NAT in their respective regions.
  dynamic "subnetwork" {
    for_each = [for subnet in var.private_subnets : subnet if subnet.region == each.key]
    content {
      name                    = google_compute_subnetwork.private[subnetwork.value.name].self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  # Enable NAT logging if `enable_logging = true`.
  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      enable = true
      filter = var.log_config.nat_filter
    }
  }
}

# Cloud Storage Bucket for Logs
# - Created only if `enable_logging = true` and `cloud_logging_enabled = false`.
# - Stores VPC flow logs and firewall logs.
# - Requires `CustomStorageRole` for the service account to avoid permission errors.
resource "google_storage_bucket" "logs_bucket" {
  count    = var.enable_logging && !var.cloud_logging_enabled ? 1 : 0
  name     = "${var.network_name}-logs-${var.project_id}"
  project  = var.project_id
  location = "us-central1" # Change to desired region for log storage.
  # Enable CMEK if `enable_cmek = true` and `log_config.kms_key_id` is provided.
  dynamic "encryption" {
    for_each = var.enable_cmek && var.log_config.kms_key_id != null ? [1] : []
    content {
      default_kms_key_name = var.log_config.kms_key_id
    }
  }
  # Set retention period for logs (minimum 1 day, defined in `log_config.retention_period`).
  retention_policy {
    retention_period = var.log_config.retention_period
  }
}

# Log Sink for All Logs to Cloud Storage
# - Routes VPC, NAT, and firewall logs to the storage bucket if `cloud_logging_enabled = false`.
resource "google_logging_project_sink" "logs_sink" {
  count       = var.enable_logging && !var.cloud_logging_enabled ? 1 : 0
  name        = "${var.network_name}-logs-sink"
  project     = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.logs_bucket[0].name}"
  # Filter logs for subnets, routers, NAT, and firewall rules.
  filter                 = "resource.type=gce_subnetwork OR resource.type=gce_router OR resource.type=cloud_nat OR resource.type=gce_firewall_rule"
  unique_writer_identity = true
}

# Grant sink writer identity permission
# - Allows the log sink to write to the storage bucket.
resource "google_storage_bucket_iam_member" "logs_sink_writer" {
  count  = var.enable_logging && !var.cloud_logging_enabled ? 1 : 0
  bucket = google_storage_bucket.logs_bucket[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.logs_sink[0].writer_identity
}

# Custom Firewall Rules
# - Define ingress/egress rules in `firewall_rules` variable.
# - Use `target_tags` to apply rules to specific resources.
resource "google_compute_firewall" "custom_rules" {
  for_each  = var.firewall_rules
  name      = "${var.network_name}-${each.key}"
  network   = google_compute_network.vpc.id
  project   = var.project_id
  direction = each.value.direction
  priority  = each.value.priority
  # Define allowed protocols and ports.
  dynamic "allow" {
    for_each = each.value.allow != null ? each.value.allow : []
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  # Define denied protocols and ports.
  dynamic "deny" {
    for_each = each.value.deny != null ? each.value.deny : []
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
  source_ranges      = each.value.source_ranges
  destination_ranges = each.value.destination_ranges
  target_tags        = each.value.target_tags
  # Enable firewall logging if `enable_logging = true`.
  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      metadata = var.log_config.firewall_metadata
    }
  }
}

# Default Deny-All Egress Firewall Rule
# - Blocks all outbound traffic unless explicitly allowed by other rules.
# - Enhances security by enforcing least privilege for egress.
resource "google_compute_firewall" "default_deny_egress" {
  name      = "${var.network_name}-default-deny-egress"
  network   = google_compute_network.vpc.id
  project   = var.project_id
  direction = "EGRESS"
  priority  = 65535 # Lowest priority to allow specific rules to override.
  deny {
    protocol = "all"
  }
  destination_ranges = ["0.0.0.0/0"]
  dynamic "log_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      metadata = var.log_config.firewall_metadata
    }
  }
}
