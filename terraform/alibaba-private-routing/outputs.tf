output "private_route_table_id" {
  value       = alicloud_route_table.private_rt.id
  description = "The ID of the private custom route table"
}

output "public_route_table_id" {
  value       = alicloud_route_table.public_rt.id
  description = "The ID of the public custom route table"
}

output "private_attached_vswitches" {
  value       = [for a in alicloud_route_table_attachment.private_vswitch_attach : a.vswitch_id]
  description = "List of attached private vSwitch IDs"
}

output "public_attached_vswitches" {
  value       = [for a in alicloud_route_table_attachment.public_vswitch_attach : a.vswitch_id]
  description = "List of attached public vSwitch IDs"
}

output "chr_private_eni_id" {
  value       = var.chr_private_eni_id
  description = "Next hop ENI for transit routes"
}
