# 1. Data Sources for existing VNet, Subnets, Image, and DES
data "azurerm_subnet" "peering_subnet" {
  name                 = var.peering_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.network_resource_group_name
}

data "azurerm_subnet" "private_subnet" {
  name                 = var.private_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.network_resource_group_name
}

data "azurerm_image" "chr_image" {
  name                = var.custom_image_name
  resource_group_name = var.compute_resource_group_name
}

data "azurerm_disk_encryption_set" "des" {
  name                = var.disk_encryption_set_name
  resource_group_name = var.security_resource_group_name
}

# 2. Public IP for Peering / WAN NIC
resource "azurerm_public_ip" "peering_pip" {
  name                = "pip-${var.vm_name}"
  location            = var.location
  resource_group_name = var.network_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name        = "pip-${var.vm_name}"
    Environment = "production"
    ManagedBy   = "terraform"
    Role        = "peering-wan"
  }
}

# 3. Network Security Group (NSG) for Peering / WAN Interface
resource "azurerm_network_security_group" "peering_nsg" {
  name                = "nsg-${var.vm_name}-peering"
  location            = var.location
  resource_group_name = var.network_resource_group_name

  security_rule {
    name                       = "Allow-IPsec-IKE"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "500"
    source_address_prefixes    = ["${var.gcp_chr_public_ip}/32", "${var.aliyun_chr_public_ip}/32"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-IPsec-NAT-T"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4500"
    source_address_prefixes    = ["${var.gcp_chr_public_ip}/32", "${var.aliyun_chr_public_ip}/32"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-IPsec-ESP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["${var.gcp_chr_public_ip}/32", "${var.aliyun_chr_public_ip}/32"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-BGP"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "179"
    source_address_prefixes    = ["${var.gcp_chr_public_ip}/32", "${var.aliyun_chr_public_ip}/32"]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Management-SSH"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_source_ip_prefixes
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Management-Winbox"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8291"
    source_address_prefixes    = var.admin_source_ip_prefixes
    destination_address_prefix = "*"
  }

  tags = {
    Name        = "nsg-${var.vm_name}-peering"
    Environment = "production"
    ManagedBy   = "terraform"
    Role        = "peering-nsg"
  }
}

# 4. Network Security Group (NSG) for Private / LAN Interface
resource "azurerm_network_security_group" "private_nsg" {
  name                = "nsg-${var.vm_name}-private"
  location            = var.location
  resource_group_name = var.network_resource_group_name

  security_rule {
    name                       = "Allow-All-VNet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Name        = "nsg-${var.vm_name}-private"
    Environment = "production"
    ManagedBy   = "terraform"
    Role        = "private-nsg"
  }
}

# 5. Network Interfaces (NIC 0: Peering, NIC 1: Private)
resource "azurerm_network_interface" "peering_nic" {
  name                  = "nic-${var.vm_name}-peering"
  location              = var.location
  resource_group_name   = var.network_resource_group_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "ipconfig-peering"
    subnet_id                     = data.azurerm_subnet.peering_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.peering_private_ip
    public_ip_address_id          = azurerm_public_ip.peering_pip.id
  }

  tags = {
    Name        = "nic-${var.vm_name}-peering"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_network_interface_security_group_association" "peering_nic_nsg" {
  network_interface_id      = azurerm_network_interface.peering_nic.id
  network_security_group_id = azurerm_network_security_group.peering_nsg.id
}

resource "azurerm_network_interface" "private_nic" {
  name                  = "nic-${var.vm_name}-private"
  location              = var.location
  resource_group_name   = var.network_resource_group_name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "ipconfig-private"
    subnet_id                     = data.azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_private_ip
  }

  tags = {
    Name        = "nic-${var.vm_name}-private"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_network_interface_security_group_association" "private_nic_nsg" {
  network_interface_id      = azurerm_network_interface.private_nic.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# 6. MikroTik CHR Linux Virtual Machine with CMK Encrypted OS Disk
resource "azurerm_linux_virtual_machine" "chr_vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.compute_resource_group_name
  size                = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.peering_nic.id,
    azurerm_network_interface.private_nic.id,
  ]

  admin_username                  = "azureuser"
  disable_password_authentication = false
  admin_password                  = "ChrInitialSecret2026!"

  source_image_id = data.azurerm_image.chr_image.id

  os_disk {
    name                   = "osdisk-${var.vm_name}"
    caching                = "ReadWrite"
    storage_account_type   = "StandardSSD_LRS"
    disk_encryption_set_id = data.azurerm_disk_encryption_set.des.id
  }

  tags = {
    Name        = var.vm_name
    Environment = "production"
    ManagedBy   = "terraform"
    Role        = "cloud-router"
  }
}
