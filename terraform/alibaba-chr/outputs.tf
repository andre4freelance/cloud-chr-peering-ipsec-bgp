output "instance_id" {
  description = "The ID of the MikroTik CHR instance"
  value       = alicloud_instance.chr.id
}

output "instance_name" {
  description = "The name of the MikroTik CHR instance"
  value       = alicloud_instance.chr.instance_name
}

output "public_ip" {
  description = "The static Elastic IP (EIP) assigned to the primary interface"
  value       = alicloud_eip_address.chr_eip.ip_address
}

output "primary_peering_private_ip" {
  description = "The static private IP on the primary peering interface"
  value       = alicloud_instance.chr.private_ip
}

output "secondary_private_eni_ip" {
  description = "The static private IP on the secondary private interface"
  value       = alicloud_ecs_network_interface.private_eni.primary_ip_address
}

output "peering_security_group_id" {
  description = "Dedicated Security Group for peering interface"
  value       = alicloud_security_group.peering_sg.id
}

output "private_security_group_id" {
  description = "Dedicated Security Group for private interface"
  value       = alicloud_security_group.private_sg.id
}
