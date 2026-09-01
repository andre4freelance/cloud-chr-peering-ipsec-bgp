output "private_route_table_name" {
  description = "The name of the private subnet route table"
  value       = "rt-nextops-private"
}

output "public_route_table_id" {
  description = "The ID of the newly created public subnet route table"
  value       = azurerm_route_table.public_rt.id
}

output "next_hop_chr_private_ip" {
  description = "The Next Hop Virtual Appliance IP (chr-peering private interface)"
  value       = var.chr_private_ip
}
