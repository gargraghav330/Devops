# ===========================
# File: variables.tf
# Description: Defines input variables for the root module.

# Authentication:
#   - Run `gcloud auth application-default login` for ADC or set `GOOGLE_APPLICATION_CREDENTIALS` environment variable.
#     Example: `export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/terraform-key.json`
# - See `README.md` for setup instructions and VPC configuration examples.
# ==========================

# GCP project ID where resources will be created (e.g., "playground-s-11-f85b934d").
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Email of the service account used by Terraform (e.g., "cli-service-account-1@project.iam.gserviceaccount.com").
# Must have roles: `compute.admin`, `logging.admin`, `CustomStorageRole` (if Cloud Storage logging), `cloudkms.cryptoKeyEncrypterDecrypter` (if CMEK).
variable "service_account_email" {
  description = "Email of the service account used by Terraform"
  type        = string
}

# List of VPC configurations.
variable "vpcs" {
  description = "List of VPC configurations"
  type = list(object({
    network_name            = string
    auto_create_subnetworks = bool
    routing_mode            = string
    enable_ipv6             = bool
    mtu                     = number
    enable_logging          = bool
    cloud_logging_enabled   = bool
    enable_cmek             = bool
    log_config = object({
      aggregation_interval = string
      flow_sampling        = number
      metadata             = string
      nat_filter           = string
      firewall_metadata    = string
      kms_key_id           = string
      retention_period     = number
    })
    enable_nat               = bool
    create_cloud_router      = bool
    best_path_selection_mode = string
    cloud_router_config = object({
      name    = string
      bgp_asn = number
      bgp_peers = list(object({
        peer_ip  = string
        peer_asn = number
      }))
    })
    nat_config = object({
      nat_ip_allocate_option              = string
      nat_ips                             = list(string)
      enable_logging                      = bool
      log_filter                          = string
      min_ports_per_vm                    = number
      max_ports_per_vm                    = number
      enable_endpoint_independent_mapping = bool
    })
    enable_firewall = bool
    firewall_rules = map(object({
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
    labels = map(string)
    public_subnets = list(object({
      name         = string
      cidr         = string
      region       = string
      network_tags = list(string)
      secondary_ranges = list(object({
        range_name    = string
        ip_cidr_range = string
      }))
    }))
    private_subnets = list(object({
      name         = string
      cidr         = string
      region       = string
      network_tags = list(string)
      secondary_ranges = list(object({
        range_name    = string
        ip_cidr_range = string
      }))
    }))
  }))
}
