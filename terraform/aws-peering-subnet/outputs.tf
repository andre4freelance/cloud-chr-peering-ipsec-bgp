output "peering_subnet_id" {
  description = "ID of the created peering subnet"
  value       = aws_subnet.peering_subnet.id
}

output "peering_subnet_cidr" {
  description = "CIDR block of the peering subnet"
  value       = aws_subnet.peering_subnet.cidr_block
}

output "peering_subnet_az" {
  description = "Availability Zone of the peering subnet"
  value       = aws_subnet.peering_subnet.availability_zone
}

output "route_table_association_id" {
  description = "ID of the Route Table association"
  value       = aws_route_table_association.peering_rta.id
}
