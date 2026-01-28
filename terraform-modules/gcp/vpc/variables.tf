# ===========================
# File: modules/vpc/variables.tf
# Description: Defines input variables for the VPC module.
# ===========================

# GCP project ID where the VPC will be created.
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Name of the VPC network (e.g., "dev-vpc").
# Must be lowercase, numbers, and hyphens only.
variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.network_name))
    error_message = "Network name must contain only lowercase letters, numbers, and hyphens."
  }
}

# Whether to auto-create subnets or use custom subnets.
# Set to `false` (default) for custom control via `public_subnets` and `private_subnets`.
# Set to `true` for GCP to create subnets in each region (less control).
variable "auto_create_subnetworks" {
  description = "Whether to auto-create subnetworks or use custom subnets"
  type        = bool
  default     = false
}

# Network routing mode.
# Use `REGIONAL` (default) for traffic within a region.
# Use `GLOBAL` for cross-region routing (e.g., multi-region GKE).
variable "routing_mode" {
  description = "The network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"
}

# Enable ULA internal IPv6 for the VPC.
# Set to `true` only if IPv6 is required (rarely needed).
variable "enable_ipv6" {
  description = "Enable ULA internal IPv6"
  type        = bool
  default     = false
}

# MTU for the VPC network.
# Leave `null` (default) for 1460 or set a custom value (e.g., 1500) for performance tuning.
variable "vpc_mtu" {
  description = "MTU for the VPC network (optional, default 1460)"
  type        = number
  default     = null
}

# Enable logging for subnets, NAT, and firewall rules.
# Set to `true` to enable flow logs and firewall logs (requires `log_config` settings).
variable "enable_logging" {
  description = "Enable logging for all supported resources"
  type        = bool
  default     = false
}

# Store logs in Cloud Logging or Cloud Storage.
# Set to `true` (default) for Cloud Logging (recommended, no bucket permissions needed).
# Set to `false` for Cloud Storage (requires `CustomStorageRole` for service account).
variable "cloud_logging_enabled" {
  description = "Store logs in Cloud Logging (true) or Cloud Storage (false)"
  type        = bool
  default     = true
}

# Enable Customer-Managed Encryption Key (CMEK) for Cloud Storage logs.
# Set to `true` and provide `log_config.kms_key_id` for CMEK.
# Requires `roles/cloudkms.cryptoKeyEncrypterDecrypter` for the service account.
variable "enable_cmek" {
  description = "Enable Customer-Managed Encryption Key (CMEK) for Cloud Storage logs"
  type        = bool
  default     = false
}

# Logging configuration for flow logs, NAT, and firewall rules.
# Customize aggregation interval, sampling rate, metadata, and retention period.
variable "log_config" {
  description = "Configuration for logging"
  type = object({
    aggregation_interval = string # e.g., "INTERVAL_5_SEC" for log frequency.
    flow_sampling        = number # Sampling rate (0.0 to 1.0, e.g., 0.5 for 50%).
    metadata             = string # Metadata inclusion (e.g., "INCLUDE_ALL_METADATA").
    nat_filter           = string # NAT log filter (e.g., "ALL", "ERRORS_ONLY").
    firewall_metadata    = string # Firewall log metadata (e.g., "INCLUDE_ALL_METADATA").
    kms_key_id           = string # KMS key ID for CMEK (null if not used).
    retention_period     = number # Retention period in seconds (minimum 1 day = 86400).
  })
  default = {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
    nat_filter           = "ALL"
    firewall_metadata    = "INCLUDE_ALL_METADATA"
    kms_key_id           = null
    retention_period     = 2592000 # 30 days
  }
  validation {
    condition     = var.log_config.retention_period >= 86400
    error_message = "Retention period must be at least 1 day (86400 seconds)."
  }
}

# Enable Cloud NAT for private subnets to access the internet.
# Set to `true` to create NAT gateways (configure `nat_config` for details).
variable "enable_nat" {
  description = "Enable Cloud NAT for private subnets"
  type        = bool
  default     = false
}

# Create a custom Cloud Router for NAT.
# Set to `true` and configure `cloud_router_config` for advanced routing (e.g., BGP).
variable "create_cloud_router" {
  description = "Create a custom Cloud Router for NAT"
  type        = bool
  default     = false
}

# Configuration for custom Cloud Router.
# Specify name, BGP ASN, and peers if `create_cloud_router = true`.
variable "cloud_router_config" {
  description = "Configuration for custom Cloud Router"
  type = object({
    name    = string
    bgp_asn = number
    bgp_peers = list(object({
      peer_ip  = string
      peer_asn = number
    }))
  })
  default = {
    name      = null
    bgp_asn   = null
    bgp_peers = []
  }
}

# Configuration for Cloud NAT.
# Customize IP allocation, logging, and port settings.
variable "nat_config" {
  description = "Configuration for Cloud NAT"
  type = object({
    nat_ip_allocate_option              = string       # "AUTO_ONLY" or "MANUAL_ONLY".
    nat_ips                             = list(string) # List of static IPs if MANUAL_ONLY.
    enable_logging                      = bool         # Enable NAT logging.
    log_filter                          = string       # Log filter (e.g., "ALL").
    min_ports_per_vm                    = number       # Minimum ports per VM.
    max_ports_per_vm                    = number       # Maximum ports per VM.
    enable_endpoint_independent_mapping = bool         # Enable endpoint-independent mapping.
  })
  default = {
    nat_ip_allocate_option              = "AUTO_ONLY"
    nat_ips                             = []
    enable_logging                      = false
    log_filter                          = "ALL"
    min_ports_per_vm                    = 64
    max_ports_per_vm                    = 65536
    enable_endpoint_independent_mapping = false
  }
}

# List of public subnets.
# Define name, CIDR, region, network tags, and secondary ranges (e.g., for GKE).
variable "public_subnets" {
  description = "List of public subnets"
  type = list(object({
    name         = string
    cidr         = string
    region       = string
    network_tags = list(string)
    secondary_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  default = []
  validation {
    condition     = alltrue([for subnet in var.public_subnets : can(cidrnetmask(subnet.cidr))])
    error_message = "Invalid CIDR block in public_subnets."
  }
}

# List of private subnets.
# Define name, CIDR, region, network tags, and secondary ranges (e.g., for GKE).
variable "private_subnets" {
  description = "List of private subnets"
  type = list(object({
    name         = string
    cidr         = string
    region       = string
    network_tags = list(string)
    secondary_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  default = []
  validation {
    condition     = alltrue([for subnet in var.private_subnets : can(cidrnetmask(subnet.cidr))])
    error_message = "Invalid CIDR block in private_subnets."
  }
}

# Map of firewall rules.
# Define ingress/egress rules with direction, priority, allow/deny protocols, and target tags.
variable "firewall_rules" {
  description = "Map of firewall rules"
  type = map(object({
    direction = string
    priority  = number
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
    deny = list(object({
      protocol = string
      ports    = list(string)
    }))
    source_ranges      = list(string)
    destination_ranges = list(string)
    target_tags        = list(string)
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.firewall_rules : contains(["INGRESS", "EGRESS"], v.direction) &&
      v.priority >= 1000 && v.priority <= 65535
    ])
    error_message = "Firewall rules must have direction INGRESS or EGRESS and priority between 1000 and 65535."
  }
}

# Best path selection mode for Cloud Router.
# Use `LEGACY` (default) or `STANDARD` for advanced routing.
variable "best_path_selection_mode" {
  description = "Best path selection mode for Cloud Router"
  type        = string
  default     = null
  validation {
    condition     = var.best_path_selection_mode == null ? true : contains(["LEGACY", "STANDARD"], var.best_path_selection_mode)
    error_message = "Best path selection mode must be one of: LEGACY, STANDARD."
  }
}

variable "service_account_email" {
  description = "Service account email to use for the project"
  type        = string
}
