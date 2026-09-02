# 1. Data Sources for existing Subnets and existing Private Route Table
data "azurerm_subnet" "public_subnet" {
  name                 = "subnet-public"
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.network_resource_group_name
}

data "azurerm_subnet" "private_subnet" {
  name                 = "subnet-private"
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.network_resource_group_name
}

# ==============================================================================
# ROUTING UNTUK SUBNET-PRIVATE
# ==============================================================================
# Menambahkan static route ke Aliyun & GCP pada route table eksisting: rt-nextops-private
# Next Hop spesifik diarahkan ke Private Interface CHR (10.126.1.100)

resource "azurerm_route" "private_to_aliyun" {
  name                   = "to-aliyun-via-chr"
  resource_group_name    = var.network_resource_group_name
  route_table_name       = "rt-nextops-private"
  address_prefix         = var.aliyun_vpc_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.chr_private_ip
}

resource "azurerm_route" "private_to_aliyun_spoke" {
  name                   = "to-aliyun-spoke-via-chr"
  resource_group_name    = var.network_resource_group_name
  route_table_name       = "rt-nextops-private"
  address_prefix         = var.aliyun_spoke_vpc_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.chr_private_ip
}

resource "azurerm_route" "private_to_gcp" {
  name                   = "to-gcp-via-chr"
  resource_group_name    = var.network_resource_group_name
  route_table_name       = "rt-nextops-private"
  address_prefix         = var.gcp_vpc_cidr
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.chr_private_ip
}

# ==============================================================================
# ROUTING UNTUK SUBNET-PUBLIC
# ==============================================================================
# Membuat route table baru khusus untuk subnet-public dan meng-attach-nya.
# Subnet-public tetap default route ke Internet, tapi ke Aliyun & GCP lewat CHR private IP.

resource "azurerm_route_table" "public_rt" {
  name                = "rt-nextops-public"
  location            = var.location
  resource_group_name = var.network_resource_group_name

  route {
    name                   = "to-aliyun-via-chr"
    address_prefix         = var.aliyun_vpc_cidr
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.chr_private_ip
  }

  route {
    name                   = "to-aliyun-spoke-via-chr"
    address_prefix         = var.aliyun_spoke_vpc_cidr
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.chr_private_ip
  }

  route {
    name                   = "to-gcp-via-chr"
    address_prefix         = var.gcp_vpc_cidr
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.chr_private_ip
  }

  tags = {
    Name        = "rt-nextops-public"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "nextops"
  }
}

resource "azurerm_subnet_route_table_association" "public_subnet_rt" {
  subnet_id      = data.azurerm_subnet.public_subnet.id
  route_table_id = azurerm_route_table.public_rt.id
}
