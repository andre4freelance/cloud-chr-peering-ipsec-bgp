output "peer_connection_id" {
  value       = alicloud_vpc_peer_connection.hub_to_spoke.id
  description = "The ID of the VPC Peer Connection"
}

output "peer_connection_status" {
  value       = alicloud_vpc_peer_connection.hub_to_spoke.status
  description = "The status of the VPC Peer Connection"
}

output "hub_vpc_id" {
  value       = var.hub_vpc_id
  description = "Hub VPC ID"
}

output "spoke_vpc_id" {
  value       = var.spoke_vpc_id
  description = "Spoke VPC ID"
}
