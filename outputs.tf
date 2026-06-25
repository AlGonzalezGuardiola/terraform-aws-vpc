output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "IDs of the isolated subnets."
  value       = aws_subnet.isolated[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway (empty string if no public subnets)."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : ""
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "Public Elastic IPs of the NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : ""
}

output "private_route_table_ids" {
  description = "IDs of the private route tables (one per AZ)."
  value       = aws_route_table.private[*].id
}

output "isolated_route_table_id" {
  description = "ID of the isolated route table."
  value       = length(aws_route_table.isolated) > 0 ? aws_route_table.isolated[0].id : ""
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log (empty string if disabled)."
  value       = length(aws_flow_log.this) > 0 ? aws_flow_log.this[0].id : ""
}
