output "instance_id" {
  description = "ECS Instance ID of MikroTik CHR"
  value       = alicloud_instance.chr.id
}

output "instance_name" {
  description = "Name of MikroTik CHR"
  value       = alicloud_instance.chr.instance_name
}

output "peering_public_ip" {
  description = "Static Elastic IP attached to primary interface"
  value       = alicloud_eip_address.chr_eip.ip_address
}

output "peering_private_ip" {
  description = "Private IP on the primary peering interface (ether1)"
  value       = alicloud_instance.chr.private_ip
}

output "private_eni_id" {
  description = "Secondary Network Interface ID (ether2 / LAN side)"
  value       = alicloud_ecs_network_interface.private_eni.id
}

output "private_eni_ip" {
  description = "Private IP on the secondary interface (ether2)"
  value       = alicloud_ecs_network_interface.private_eni.primary_ip_address
}

output "peering_sg_id" {
  description = "Security Group ID for primary peering interface"
  value       = alicloud_security_group.peering_sg.id
}

output "private_sg_id" {
  description = "Security Group ID for secondary private interface"
  value       = alicloud_security_group.private_sg.id
}
