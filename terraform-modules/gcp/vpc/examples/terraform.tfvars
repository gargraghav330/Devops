# ===========================
# File: terraform.tfvars
# Description: Configuration file for the root module variables.
# ===========================

# GCP project ID (e.g., "playground-s-11-f85b934d").
project_id = "playground-s-11-f85b934d"

# Service account email used by Terraform.
# Must have roles: `compute.admin`, `logging.admin`, `CustomStorageRole` (if Cloud Storage logging), `cloudkms.cryptoKeyEncrypterDecrypter` (if CMEK).
service_account_email = "cli-service-account-1@playground-s-11-f85b934d.iam.gserviceaccount.com"

# List of VPC configurations.
# Defines one or more VPCs with subnets, NAT, firewall rules, logging, and labels.
vpcs = [
  {
    network_name = "dev-vpc"
    # Set to `false` for custom subnets (recommended) or `true` for auto-created subnets.
    auto_create_subnetworks = false
    # Use `REGIONAL` for intra-region routing or `GLOBAL` for cross-region.
    routing_mode = "REGIONAL"
    # Enable IPv6 only if required (rarely needed).
    enable_ipv6 = false
    # Leave `null` for default MTU (1460) or set a custom value (e.g., 1500).
    mtu = null
    # Enable logging for subnets, NAT, and firewall rules.
    enable_logging = true
    # Use Cloud Logging (true) to avoid bucket permissions or Cloud Storage (false) with `CustomStorageRole`.
    cloud_logging_enabled = true
    # Enable CMEK for Cloud Storage logs (requires `log_config.kms_key_id` and IAM role).
    enable_cmek = false
    # Logging configuration (retention_period in seconds, e.g., 2592000 = 30 days).
    log_config = {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
      nat_filter           = "ALL"
      firewall_metadata    = "INCLUDE_ALL_METADATA"
      kms_key_id           = null
      retention_period     = 2592000 # 30 days; minimum 86400 (1 day)
    }
    # Enable Cloud NAT for private subnets to access the internet.
    enable_nat = true
    # Create a custom Cloud Router (advanced; not needed for basic NAT).
    create_cloud_router = false
    # BGP path selection mode (null for default "LEGACY").
    best_path_selection_mode = null
    # Cloud Router configuration (leave default if `create_cloud_router = false`).
    cloud_router_config = {
      name      = null
      bgp_asn   = null
      bgp_peers = []
    }
    # Cloud NAT configuration.
    nat_config = {
      nat_ip_allocate_option              = "AUTO_ONLY" # Use "MANUAL_ONLY" with `nat_ips` for static IPs.
      nat_ips                             = []
      enable_logging                      = false
      log_filter                          = "ALL"
      min_ports_per_vm                    = 64
      max_ports_per_vm                    = 65536
      enable_endpoint_independent_mapping = false
    }
    # Enable firewall rules (including default deny-all egress rule in `modules/vpc/main.tf`).
    enable_firewall = true
    # Define custom firewall rules.
    firewall_rules = {
      allow-ssh = {
        direction = "INGRESS"
        priority  = 1000
        allow     = [{ protocol = "tcp", ports = ["22"] }]
        deny      = []
        # Restrict to specific CIDRs in production (e.g., ["203.0.113.0/24"]) instead of "0.0.0.0/0".
        source_ranges      = ["0.0.0.0/0"]
        destination_ranges = []
        target_tags        = ["ssh-access"]
      }
    }
    # Labels for resource organization and cost tracking.
    labels = {
      environment = "dev"
      owner       = "team"
    }
    # Public subnets for resources with public IPs (e.g., load balancers).
    public_subnets = [
      {
        name             = "dev-subnet-public-1"
        cidr             = "10.0.1.0/24"
        region           = "us-central1"
        network_tags     = ["public"]
        secondary_ranges = []
      },
      {
        name             = "dev-subnet-public-2"
        cidr             = "10.0.2.0/24"
        region           = "us-central1"
        network_tags     = ["public"]
        secondary_ranges = []
      }
    ]
    # Private subnets for resources without public IPs (e.g., GKE nodes, VMs).
    private_subnets = [
      {
        name         = "dev-subnet-a"
        cidr         = "10.0.10.0/24"
        region       = "us-central1"
        network_tags = ["private", "gke"]
        secondary_ranges = [
          {
            range_name    = "pods"
            ip_cidr_range = "10.1.0.0/16"
          },
          {
            range_name    = "services"
            ip_cidr_range = "10.2.0.0/20"
          }
        ]
      },
      {
        name         = "dev-subnet-b"
        cidr         = "10.0.20.0/24"
        region       = "us-central1"
        network_tags = ["private", "gke"]
        secondary_ranges = [
          {
            range_name    = "pods"
            ip_cidr_range = "10.3.0.0/16"
          },
          {
            range_name    = "services"
            ip_cidr_range = "10.4.0.0/20"
          }
        ]
      },
      {
        name         = "dev-subnet-c"
        cidr         = "10.0.30.0/24"
        region       = "us-central1"
        network_tags = ["private", "gke"]
        secondary_ranges = [
          {
            range_name    = "pods"
            ip_cidr_range = "10.5.0.0/16"
          },
          {
            range_name    = "services"
            ip_cidr_range = "10.6.0.0/20"
          }
        ]
      }
    ]
  }
]
