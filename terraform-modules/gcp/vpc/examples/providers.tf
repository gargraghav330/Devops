# ===========================
# File: providers.tf
# Description: Configures Terraform providers for GCP and time resources.

# Setup:
# - Run `gcloud auth application-default login` for ADC.
# - Alternatively, set `GOOGLE_APPLICATION_CREDENTIALS`:
#   ```bash
#   export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/terraform-key.json
#   ```
# - Ensure Terraform version 1.5+ and provider versions are compatible.
# ===========================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.39.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.39.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.0"
    }
  }
}
