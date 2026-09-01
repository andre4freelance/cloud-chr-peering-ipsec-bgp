output "subnet_id" {
  description = "The ID of the created peering subnet"
  value       = azurerm_subnet.peering_subnet.id
}

output "subnet_name" {
  description = "The name of the created peering subnet"
  value       = azurerm_subnet.peering_subnet.name
}

output "address_prefixes" {
  description = "The address prefixes assigned to the peering subnet"
  value       = azurerm_subnet.peering_subnet.address_prefixes
}
