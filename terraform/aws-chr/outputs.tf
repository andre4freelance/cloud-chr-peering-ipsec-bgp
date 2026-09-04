output "instance_id" {
  description = "EC2 Instance ID of the MikroTik CHR"
  value       = aws_instance.chr.id
}

output "public_ip" {
  description = "Static Public Elastic IP of the MikroTik CHR"
  value       = aws_eip.chr_eip.public_ip
}

output "wan_private_ip" {
  description = "Private IP of WAN interface (ether1)"
  value       = aws_network_interface.chr_wan_eni.private_ip
}

output "wan_eni_id" {
  description = "ENI ID of WAN interface"
  value       = aws_network_interface.chr_wan_eni.id
}

output "lan_private_ip" {
  description = "Private IP of LAN interface (ether2)"
  value       = aws_network_interface.chr_lan_eni.private_ip
}

output "lan_eni_id" {
  description = "ENI ID of LAN interface"
  value       = aws_network_interface.chr_lan_eni.id
}

output "peering_security_group_id" {
  description = "Security Group ID for WAN/Peering"
  value       = aws_security_group.chr_peering_sg.id
}

output "private_security_group_id" {
  description = "Security Group ID for LAN/Private"
  value       = aws_security_group.chr_private_sg.id
}
