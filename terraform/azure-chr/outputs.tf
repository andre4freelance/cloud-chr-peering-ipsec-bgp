output "vm_id" {
  description = "The ID of the MikroTik CHR VM"
  value       = azurerm_linux_virtual_machine.chr_vm.id
}

output "vm_name" {
  description = "The Name of the MikroTik CHR VM"
  value       = azurerm_linux_virtual_machine.chr_vm.name
}

output "public_ip_address" {
  description = "The Static Public IP assigned to the Peering interface"
  value       = azurerm_public_ip.peering_pip.ip_address
}

output "peering_private_ip" {
  description = "The Private IP assigned to the Peering interface (NIC 0 / eth0)"
  value       = azurerm_network_interface.peering_nic.ip_configuration[0].private_ip_address
}

output "private_private_ip" {
  description = "The Private IP assigned to the Private interface (NIC 1 / eth1)"
  value       = azurerm_network_interface.private_nic.ip_configuration[0].private_ip_address
}

output "peering_nsg_id" {
  description = "The ID of the NSG attached to Peering NIC"
  value       = azurerm_network_security_group.peering_nsg.id
}

output "private_nsg_id" {
  description = "The ID of the NSG attached to Private NIC"
  value       = azurerm_network_security_group.private_nsg.id
}
