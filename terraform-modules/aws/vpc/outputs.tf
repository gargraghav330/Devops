#########################
# VPC Information
#########################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

#########################
# Subnet Outputs
#########################
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "intra_subnet_ids" {
  description = "List of intra subnet IDs"
  value       = aws_subnet.intra[*].id
}

#########################
# Route Table Outputs
#########################
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "intra_route_table_ids" {
  description = "List of intra route table IDs"
  value       = aws_route_table.intra[*].id
}

#########################
# NAT Gateway Outputs
#########################
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.nat_gateway[*].id
}

#########################
# VPC Endpoints
#########################
output "vpc_endpoint_ids" {
  description = "Map of VPC endpoint IDs by service (e.g., s3, dynamodb, cloudwatch)"
  value       = { for k, v in aws_vpc_endpoint.this : k => v.id }
}
