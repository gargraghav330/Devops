# Terraform backend configuration for local state
terraform {
  backend "gcs" {
    bucket  = "<bucket-name>"
    prefix  = "terraform/state"
  }
}
