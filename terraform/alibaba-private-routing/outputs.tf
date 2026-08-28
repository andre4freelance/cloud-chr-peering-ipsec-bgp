output "route_table_id" {
  value       = alicloud_route_table.private_rt.id
  description = "The ID of the custom route table"
}

output "attached_vswitch_id" {
  value       = alicloud_route_table_attachment.private_vswitch_attach.vswitch_id
  description = "The ID of the attached private vSwitch"
}

output "default_route_nexthop" {
  value       = alicloud_route_entry.default_to_chr_eni.nexthop_id
  description = "Next hop ENI for 0.0.0.0/0"
}
