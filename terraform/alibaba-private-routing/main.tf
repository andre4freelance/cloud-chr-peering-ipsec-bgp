##############################################################################
# Custom Route Tables for Alibaba Cloud VPC (managedservice-vpc)
# 1. Private Subnets: 0.0.0.0/0, GCP (10.101.0.0/18), Azure (10.126.0.0/18) -> CHR Private ENI
# 2. Public Subnets:  GCP (10.101.0.0/18), Azure (10.126.0.0/18) -> CHR Private ENI (No 0.0.0.0/0)
# 3. Peering Subnet:  Excluded (retains default System Route Table)
##############################################################################

# ==============================================================================
# 1. ROUTING UNTUK SUBNET PRIVATE (Zone A & Zone B)
# ==============================================================================

# Custom Route Table for Private vSwitches
resource "alicloud_route_table" "private_rt" {
  vpc_id           = var.vpc_id
  route_table_name = var.private_route_table_name
  description      = "Custom route table routing egress and multi-cloud transit traffic to MikroTik CHR private ENI"
  associate_type   = "VSwitch"

  tags = {
    Name        = var.private_route_table_name
    Environment = "ManagedService"
    Project     = "managedservice"
    Tier        = "private"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "managedservice"
  }
}

# Attach Custom Route Table to Private vSwitches (Zone A & Zone B)
resource "alicloud_route_table_attachment" "private_vswitch_attach" {
  for_each       = toset(var.private_vswitch_ids)
  vswitch_id     = each.value
  route_table_id = alicloud_route_table.private_rt.id
}

# Default Route (0.0.0.0/0) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "default_to_chr_eni" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "default-via-chr"
  description           = "Default 0.0.0.0/0 route to MikroTik CHR LAN ENI for internet egress"
}

# Route ke GCP VPC (10.101.0.0/16) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "private_to_gcp" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = var.gcp_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-gcp-via-chr"
  description           = "Route to GCP Shared VPC (10.101.0.0/16) via MikroTik CHR"
}

# Route ke Azure VNet (10.126.0.0/18) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "private_to_azure" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = var.azure_vnet_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-azure-via-chr"
  description           = "Route to Azure VNet (10.126.0.0/18) via MikroTik CHR"
}

# Route ke NextOps Spoke VPC (10.151.0.0/18) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "private_to_aliyun_spoke" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = var.aliyun_spoke_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-aliyun-nextops-via-chr"
  description           = "Route to Alibaba NextOps VPC (10.151.0.0/18) via MikroTik CHR"
}

# Route ke AWS Singapore (10.29.0.0/18) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "private_to_aws_sin" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = var.aws_sin_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-aws-sin-via-chr"
  description           = "Route to AWS Singapore VPC (10.29.0.0/18) via MikroTik CHR"
}

# Route ke AWS Jakarta Managed Service (172.19.0.0/16) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "private_to_aws_jkt" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = var.aws_jkt_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-aws-jkt-via-chr"
  description           = "Route to AWS Jakarta MS VPC (172.19.0.0/16) via MikroTik CHR"
}

# ==============================================================================
# 2. ROUTING UNTUK SUBNET PUBLIC (Zone A & Zone B)
# ==============================================================================

# Custom Route Table for Public vSwitches
resource "alicloud_route_table" "public_rt" {
  vpc_id           = var.vpc_id
  route_table_name = var.public_route_table_name
  description      = "Custom route table routing multi-cloud transit traffic to MikroTik CHR private ENI"
  associate_type   = "VSwitch"

  tags = {
    Name        = var.public_route_table_name
    Environment = "ManagedService"
    Project     = "managedservice"
    Tier        = "public"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "managedservice"
  }
}

# Attach Custom Route Table to Public vSwitches (Zone A & Zone B)
resource "alicloud_route_table_attachment" "public_vswitch_attach" {
  for_each       = toset(var.public_vswitch_ids)
  vswitch_id     = each.value
  route_table_id = alicloud_route_table.public_rt.id
}

# Route ke GCP VPC (10.101.0.0/16) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "public_to_gcp" {
  route_table_id        = alicloud_route_table.public_rt.id
  destination_cidrblock = var.gcp_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-gcp-via-chr"
  description           = "Route to GCP Shared VPC (10.101.0.0/16) via MikroTik CHR"
}

# Route ke Azure VNet (10.126.0.0/18) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "public_to_azure" {
  route_table_id        = alicloud_route_table.public_rt.id
  destination_cidrblock = var.azure_vnet_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-azure-via-chr"
  description           = "Route to Azure VNet (10.126.0.0/18) via MikroTik CHR"
}

# Route ke NextOps Spoke VPC (10.151.0.0/18) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "public_to_aliyun_spoke" {
  route_table_id        = alicloud_route_table.public_rt.id
  destination_cidrblock = var.aliyun_spoke_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-aliyun-nextops-via-chr"
  description           = "Route to Alibaba NextOps VPC (10.151.0.0/18) via MikroTik CHR"
}

# Route ke AWS Singapore (10.29.0.0/18) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "public_to_aws_sin" {
  route_table_id        = alicloud_route_table.public_rt.id
  destination_cidrblock = var.aws_sin_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-aws-sin-via-chr"
  description           = "Route to AWS Singapore VPC (10.29.0.0/18) via MikroTik CHR"
}

# Route ke AWS Jakarta Managed Service (172.19.0.0/16) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "public_to_aws_jkt" {
  route_table_id        = alicloud_route_table.public_rt.id
  destination_cidrblock = var.aws_jkt_vpc_cidr
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
  name                  = "to-aws-jkt-via-chr"
  description           = "Route to AWS Jakarta MS VPC (172.19.0.0/16) via MikroTik CHR"
}

