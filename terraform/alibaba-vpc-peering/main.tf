##############################################################################
# VPC Peering between managedservice-vpc (Hub) and nextops-vpc (Production Spoke)
# Bidirectional routes across all route tables in both VPCs + Multi-Cloud Transit Routes
##############################################################################

# Get current Alibaba Cloud Account ID dynamically
data "alicloud_account" "current" {}

# ==============================================================================
# 1. VPC PEERING CONNECTION
# ==============================================================================

resource "alicloud_vpc_peer_connection" "hub_to_spoke" {
  peer_connection_name = "peer-managedservice-to-nextops"
  vpc_id               = var.hub_vpc_id
  accepting_ali_uid    = data.alicloud_account.current.id
  accepting_region_id  = var.region
  accepting_vpc_id     = var.spoke_vpc_id
  description          = "VPC Peering between managedservice-vpc (Hub) and nextops-vpc (Spoke)"
  resource_group_id    = var.hub_resource_group_id

  tags = {
    Name        = "peer-managedservice-to-nextops"
    Environment = "Production"
    ManagedBy   = "terraform"
    Project     = "nextops"
    Owner       = "ics-ms"
  }
}

# ==============================================================================
# 2. ROUTES DI HUB VPC (managedservice-vpc -> nextops-vpc: 10.151.0.0/18)
# ==============================================================================

# 2a. Route on Private Route Table (managedservice-private-rt)
resource "alicloud_route_entry" "hub_private_to_spoke" {
  route_table_id        = var.hub_private_route_table_id
  destination_cidrblock = var.spoke_vpc_cidr
  nexthop_type          = "VpcPeer"
  nexthop_id            = alicloud_vpc_peer_connection.hub_to_spoke.id
}

# 2b. Route on Public Route Table (managedservice-public-rt)
resource "alicloud_route_entry" "hub_public_to_spoke" {
  route_table_id        = var.hub_public_route_table_id
  destination_cidrblock = var.spoke_vpc_cidr
  nexthop_type          = "VpcPeer"
  nexthop_id            = alicloud_vpc_peer_connection.hub_to_spoke.id
}

# 2c. Route on System Route Table (covers peering subnet / CHR ether1)
resource "alicloud_route_entry" "hub_system_to_spoke" {
  route_table_id        = var.hub_system_route_table_id
  destination_cidrblock = var.spoke_vpc_cidr
  nexthop_type          = "VpcPeer"
  nexthop_id            = alicloud_vpc_peer_connection.hub_to_spoke.id
}

# ==============================================================================
# 3. ROUTES DI SPOKE VPC (nextops-vpc -> managedservice-vpc & Multi-Cloud Transit)
# ==============================================================================

# 3a. Route on System Route Table in nextops-vpc -> managedservice-vpc (10.151.64.0/18)
resource "alicloud_route_entry" "spoke_system_to_hub" {
  route_table_id        = var.spoke_system_route_table_id
  destination_cidrblock = var.hub_vpc_cidr
  nexthop_type          = "VpcPeer"
  nexthop_id            = alicloud_vpc_peer_connection.hub_to_spoke.id
}

# 3b. Route on System Route Table in nextops-vpc -> GCP VPC (10.101.0.0/18 via VPC Peer)
resource "alicloud_route_entry" "spoke_system_to_gcp" {
  route_table_id        = var.spoke_system_route_table_id
  destination_cidrblock = var.gcp_vpc_cidr
  nexthop_type          = "VpcPeer"
  nexthop_id            = alicloud_vpc_peer_connection.hub_to_spoke.id
}

# 3c. Route on System Route Table in nextops-vpc -> Azure VNet (10.126.0.0/18 via VPC Peer)
resource "alicloud_route_entry" "spoke_system_to_azure" {
  route_table_id        = var.spoke_system_route_table_id
  destination_cidrblock = var.azure_vnet_cidr
  nexthop_type          = "VpcPeer"
  nexthop_id            = alicloud_vpc_peer_connection.hub_to_spoke.id
}
