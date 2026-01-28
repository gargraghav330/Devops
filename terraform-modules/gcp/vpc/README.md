# Terraform GCP VPC Module

## Overview

This Terraform module creates a Virtual Private Cloud (VPC) in Google Cloud Platform (GCP). It provisions custom subnets, Cloud NAT, firewall rules, logging, and IAM permissions, with support for Cloud Logging or Cloud Storage.

## Features

- Configurable VPC with regional/global routing and IPv6.
- Public and private subnets with secondary ranges.
- Optional Cloud NAT for private subnet internet access.
- Custom firewall rules with default deny-all egress.
- Logging to Cloud Logging or Cloud Storage with CMEK.
- IAM role management with propagation delay.

## Prerequisites

- Terraform 1.5+.
- Google Cloud SDK installed.
- GCP project with Compute Engine, Logging, and Storage APIs enabled.
- Service account with roles:
  - `roles/compute.admin`
  - `roles/logging.admin`
  - `CustomStorageRole` (if `cloud_logging_enabled = false`)
  - `roles/cloudkms.cryptoKeyEncrypterDecrypter` (if `enable_cmek = true`)

## Setup

### Authentication

Use Application Default Credentials (ADC):

1. Install Google Cloud SDK and authenticate:

   ```bash
   gcloud init
   gcloud auth application-default login
   ```

2. Grant roles to the service account:

   ```bash
   gcloud projects add-iam-policy-binding <project-id> --member serviceAccount:cli-service-account-1@<project-id>.iam.gserviceaccount.com --role roles/compute.admin
   gcloud projects add-iam-policy-binding <project-id> --member serviceAccount:cli-service-account-1@<project-id>.iam.gserviceaccount.com --role roles/logging.admin
   ```

### Configuration

1. Save `modules/vpc/main.tf` and `variables.tf`.

2. In `examples/complete/terraform.tfvars`, set:

   ```hcl
   project_id = "<project-id>"
   service_account_email = "cli-service-account-1@<project-id>.iam.gserviceaccount.com"
   network_name = "dev-vpc"
   ```

3. Apply:

   ```bash
   cd examples/complete/
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

## Usage

- **Standalone**: Call the module in a `main.tf` with required variables (e.g., `project_id`, `service_account_email`).
- **Integration**: Use outputs like `vpc_id` for GKE or VM modules.
- **Using examples/complete/main.tf**:
  1. Navigate to the example directory:
     ```bash
     cd examples/complete/
     ```
  2. Ensure `terraform.tfvars` is configured with:
     - `project_id = "<project-id>"`
     - `service_account_email = "cli-service-account-1@<project-id>.iam.gserviceaccount.com"`
     - `network_name = "dev-vpc"`
     - Other variables as needed (e.g., `public_subnets`, `private_subnets`, `firewall_rules`).
  3. Initialize Terraform:
     ```bash
     terraform init
     ```
  4. Plan the deployment:
     ```bash
     terraform plan -var-file=terraform.tfvars -out=plan.tfplan
     ```
  5. Apply the configuration:
     ```bash
     terraform apply plan.tfplan
     ```
  6. Verify outputs:
     ```bash
     terraform output
     ```
- **Verify**:
  - Check IAM: `gcloud projects get-iam-policy <project-id> --filter="bindings.members:cli-service-account-1@<project-id>.iam.gserviceaccount.com"`
  - Test NAT: Create a VM in `dev-subnet-a` and `curl google.com`.
  - View logs in GCP Console under Logging > Logs Explorer.

## Resources and Configuration

 1. **google_project_iam_member.service_account_storage_admin**: Grants `CustomStorageRole` for Cloud Storage logging if `cloud_logging_enabled = false`.
 2. **time_sleep.wait_for_iam**: Delays VPC creation by 60s for IAM propagation.
 3. **google_compute_network.vpc**: Creates `dev-vpc` with configurable routing and MTU.
 4. **google_compute_subnetwork.public/private**: Defines subnets with GKE ranges; logging enabled if `enable_logging = true`.
 5. **google_compute_route.default_internet**: Routes traffic to the internet gateway.
 6. **google_compute_router.nat_router_default**: Sets up Cloud Router for NAT if `enable_nat = true`.
 7. **google_compute_router_nat.nat**: Enables NAT for private subnets.
 8. **google_storage_bucket.logs_bucket**: Stores logs if `cloud_logging_enabled = false`.
 9. **google_logging_project_sink.logs_sink**: Routes logs to storage bucket.
10. **google_storage_bucket_iam_member.logs_sink_writer**: Grants sink write permissions.
11. **google_compute_firewall.custom_rules**: Applies custom rules (e.g., `allow-ssh`).
12. **google_compute_firewall.default_deny_egress**: Blocks all outbound traffic.

**Key Variables**:

- `service_account_email`: Passed from `examples/complete/terraform.tfvars`.
- `cloud_logging_enabled`: `true` for Cloud Logging, `false` for Cloud Storage.
- `enable_nat`: Enables NAT for private subnets.
- `log_config.retention_period`: Sets log retention (default: 30 days).

## Troubleshooting

- **Bucket Permissions**: Set `cloud_logging_enabled = true` or create `CustomStorageRole`.
- **IAM Propagation**: Increase `time_sleep.wait_for_iam.create_duration` to `120s`.
- **Authentication**: Verify ADC with `gcloud auth application-default print-access-token`.

## Best Practices

- Restrict firewall `source_ranges` to specific CIDRs.
- Use `cloud_logging_enabled = true` for simpler logging.
- Adjust `log_config.retention_period` for compliance.
- Prefer ADC over service account keys.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.39.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.custom_rules](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.default_deny_egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.default_internet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_router.nat_router_default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.private](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.public](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_logging_project_sink.logs_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) | resource |
| [google_storage_bucket.logs_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.logs_sink_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_create_subnetworks"></a> [auto\_create\_subnetworks](#input\_auto\_create\_subnetworks) | Whether to auto-create subnetworks or use custom subnets | `bool` | `false` | no |
| <a name="input_best_path_selection_mode"></a> [best\_path\_selection\_mode](#input\_best\_path\_selection_mode) | Best path selection mode for Cloud Router | `string` | `null` | no |
| <a name="input_cloud_logging_enabled"></a> [cloud\_logging\_enabled](#input\_cloud\_logging_enabled) | Store logs in Cloud Logging (true) or Cloud Storage (false) | `bool` | `true` | no |
| <a name="input_cloud_router_config"></a> [cloud\_router\_config](#input\_cloud\_router\_config) | Configuration for custom Cloud Router | <pre>object({<br/>    name    = string<br/>    bgp_asn = number<br/>    bgp_peers = list(object({<br/>      peer_ip  = string<br/>      peer_asn = number<br/>    }))<br/>  })</pre> | <pre>{<br/>  "bgp_asn": null,<br/>  "bgp_peers": [],<br/>  "name": null<br/>}</pre> | no |
| <a name="input_create_cloud_router"></a> [create\_cloud\_router](#input\_create\_cloud\_router) | Create a custom Cloud Router for NAT | `bool` | `false` | no |
| <a name="input_enable_cmek"></a> [enable\_cmek](#input\_enable\_cmek) | Enable Customer-Managed Encryption Key (CMEK) for Cloud Storage logs | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Enable ULA internal IPv6 | `bool` | `false` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable logging for all supported resources | `bool` | `false` | no |
| <a name="input_enable_nat"></a> [enable\_nat](#input\_enable\_nat) | Enable Cloud NAT for private subnets | `bool` | `false` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | Map of firewall rules | <pre>map(object({<br/>    direction = string<br/>    priority  = number<br/>    allow = list(object({<br/>      protocol = string<br/>      ports    = list(string)<br/>    }))<br/>    deny = list(object({<br/>      protocol = string<br/>      ports    = list(string)<br/>    }))<br/>    source_ranges      = list(string)<br/>    destination_ranges = list(string)<br/>    target_tags        = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_log_config"></a> [log\_config](#input\_config_logs) | Configuration for logging | <pre>object({<br/>    aggregation_interval = string<br/>    flow_sampling        = number<br/>    metadata             = string<br/>    nat_filter           = string<br/>    firewall_metadata    = string<br/>    kms_key_id           = string<br/>    retention_period     = number<br/>  })</pre> | <pre>{<br/>  "aggregation_interval": "INTERVAL_5_SEC",<br/>  "firewall_metadata": "INCLUDE_ALL_METADATA",<br/>  "flow_sampling": 0.5,<br/>  "kms_key_id": null,<br/>  "metadata": "INCLUDE_ALL_METADATA",<br/>  "nat_filter": "ALL",<br/>  "retention_period": 2592000<br/>}</pre> | no |
| <a name="input_nat_config"></a> [nat\_config](#input\_nat\_config) | Configuration for Cloud NAT | <pre>object({<br/>    nat_ip_allocate_option              = string<br/>    nat_ips                             = list(string)<br/>    enable_logging                      = bool<br/>    log_filter                          = string<br/>    min_ports_per_vm                    = number<br/>    max_ports_per_vm                    = number<br/>    enable_endpoint_independent_mapping = bool<br/>  })</pre> | <pre>{<br/>  "enable_endpoint_independent_mapping": false,<br/>  "enable_logging": false,<br/>  "log_filter": "ALL",<br/>  "max_ports_per_vm": 65536,<br/>  "min_ports_per_vm": 64,<br/>  "nat_ip_allocate_option": "AUTO_ONLY",<br/>  "nat_ips": []<br/>}</pre> | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | The name of the VPC network | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | List of private subnets | <pre>list(object({<br/>    name         = string<br/>    cidr         = string<br/>    region       = string<br/>    network_tags = list(string)<br/>    secondary_ranges = list(object({<br/>      range_name    = string<br/>      ip_cidr_range = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project ID | `string` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of public subnets | <pre>list(object({<br/>    name         = string<br/>    cidr         = string<br/>    region       = string<br/>    network_tags = list(string)<br/>    secondary_ranges = list(object({<br/>      range_name    = string<br/>      ip_cidr_range = string<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_routing_mode"></a> [routing\_mode](#input\_routing\_mode) | The network routing mode (REGIONAL or GLOBAL) | `string` | `"REGIONAL"` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account_email) | Service account email to use for the project | `string` | n/a | yes |
| <a name="input_vpc_mtu"></a> [vpc\_mtu](#input\_vpc\_mtu) | MTU for the VPC network (optional, default 1460) | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_ids"></a> [nat\_ids](#output\_nat\_ids) | Map of NAT names to their IDs |
| <a name="output_private_subnet_ids"></a> [private\_subnet_ids](#output\_private_subnet_ids) | Map of private subnet names to their IDs |
| <a name="output_private_subnet_self_links"></a> [private\_subnet_self_links](#output\_private_subnet_self_links) | Map of private subnet names to their self-links |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output\_public_subnet_ids) | Map of public subnet names to their IDs |
| <a name="output_public_subnet_self_links"></a> [public_subnet_self_links](#output\_public_subnet_self_links) | Map of public subnet names to their self-links |
| <a name="output_vpc_id"></a> [vpc_id](#output\_vpc_id) | ID of the VPC network |
| <a name="output_vpc_self_link"></a> [vpc_self_link](#output\_vpc_self_link) | Self-link of the VPC network |
