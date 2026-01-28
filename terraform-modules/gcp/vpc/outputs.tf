# ===========================
# File: modules/vpc/outputs.tf
# Description: Defines outputs for the VPC module to expose resource IDs and self-links.
# ===========================

output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

# Self-link of the VPC network.
output "vpc_self_link" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

# Map of private subnet names to their IDs.
output "private_subnet_ids" {
  description = "Map of private subnet names to their IDs"
  value       = { for k, v in google_compute_subnetwork.private : k => v.id }
}

# Map of private subnet names to their self-links.
output "private_subnet_self_links" {
  description = "Map of private subnet names to their self-links"
  value       = { for k, v in google_compute_subnetwork.private : k => v.self_link }
}

# Map of public subnet names to their IDs.
output "public_subnet_ids" {
  description = "Map of public subnet names to their IDs"
  value       = { for k, v in google_compute_subnetwork.public : k => v.id }
}

# Map of public subnet names to their self-links.
output "public_subnet_self_links" {
  description = "Map of public subnet names to their self-links"
  value       = { for k, v in google_compute_subnetwork.public : k => v.self_link }
}

# Map of NAT names to their IDs.
output "nat_ids" {
  description = "Map of NAT names to their IDs"
  value       = { for k, v in google_compute_router_nat.nat : k => v.id }
}
