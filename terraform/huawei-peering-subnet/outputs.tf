output "peering_subnet_id" {
  description = "ID of the created peering subnet"
  value       = huaweicloud_vpc_subnet.peering_subnet.id
}

output "peering_subnet_cidr" {
  description = "CIDR block of the peering subnet"
  value       = huaweicloud_vpc_subnet.peering_subnet.cidr
}

output "peering_subnet_az" {
  description = "Availability Zone of the peering subnet"
  value       = huaweicloud_vpc_subnet.peering_subnet.availability_zone
}

output "peering_route_table_id" {
  description = "ID of the isolated peering route table"
  value       = huaweicloud_vpc_route_table.peering_rtb.id
}
