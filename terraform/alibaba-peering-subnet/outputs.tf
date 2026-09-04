output "vswitch_id" {
  description = "The ID of the created peering vSwitch"
  value       = alicloud_vswitch.peering_vswitch.id
}

output "cidr_block" {
  description = "The CIDR block of the peering vSwitch"
  value       = alicloud_vswitch.peering_vswitch.cidr_block
}

output "zone_id" {
  description = "The zone ID of the peering vSwitch"
  value       = alicloud_vswitch.peering_vswitch.zone_id
}
