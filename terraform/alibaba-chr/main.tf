##############################################################################
# Dedicated Security Groups for each interface
##############################################################################

# Security Group 1: Dedicated for Primary Interface (Peering Subnet / Public-facing)
resource "alicloud_security_group" "peering_sg" {
  security_group_name = "${var.instance_name}-peering-sg"
  vpc_id              = var.vpc_id
  resource_group_id   = var.resource_group_id
  description         = "Dedicated Security Group for ${var.instance_name} primary peering interface"

  tags = {
    Name        = "${var.instance_name}-peering-sg"
    Environment = "Production"
    Project     = "nextops"
    Tier        = "peering"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "nextops"
  }
}

# Whitelist SSH (Port 22) from Admin IP
resource "alicloud_security_group_rule" "peering_ingress_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "${var.ssh_port}/${var.ssh_port}"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = var.admin_ip_cidr
  description       = "SSH management from Admin IP"
}

# Whitelist Winbox (Port 8291) from Admin IP
resource "alicloud_security_group_rule" "peering_ingress_winbox" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "${var.winbox_port}/${var.winbox_port}"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = var.admin_ip_cidr
  description       = "Winbox management from Admin IP"
}

# Allow IPsec IKEv2 (UDP 500) from GCP CHR Public IP
resource "alicloud_security_group_rule" "peering_ingress_ipsec_ike" {
  type              = "ingress"
  ip_protocol       = "udp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "500/500"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = "${var.gcp_chr_public_ip}/32"
  description       = "IPsec IKEv2 UDP 500 from GCP CHR Public IP"
}

# Allow IPsec NAT-Traversal (UDP 4500) from GCP CHR Public IP
resource "alicloud_security_group_rule" "peering_ingress_ipsec_natt" {
  type              = "ingress"
  ip_protocol       = "udp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "4500/4500"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = "${var.gcp_chr_public_ip}/32"
  description       = "IPsec NAT-T UDP 4500 from GCP CHR Public IP"
}

# Allow GRE Protocol from GCP CHR Public IP
resource "alicloud_security_group_rule" "peering_ingress_gre" {
  type              = "ingress"
  ip_protocol       = "gre"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = "${var.gcp_chr_public_ip}/32"
  description       = "GRE Tunnel from GCP CHR Public IP"
}

# Allow IPsec IKEv2 (UDP 500) from Azure CHR Public IP
resource "alicloud_security_group_rule" "peering_ingress_azure_ipsec_ike" {
  type              = "ingress"
  ip_protocol       = "udp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "500/500"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = "70.153.184.179/32"
  description       = "IPsec IKEv2 UDP 500 from Azure CHR Public IP"
}

# Allow IPsec NAT-Traversal (UDP 4500) from Azure CHR Public IP
resource "alicloud_security_group_rule" "peering_ingress_azure_ipsec_natt" {
  type              = "ingress"
  ip_protocol       = "udp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "4500/4500"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = "70.153.184.179/32"
  description       = "IPsec NAT-T UDP 4500 from Azure CHR Public IP"
}

# Allow GRE Protocol from Azure CHR Public IP
resource "alicloud_security_group_rule" "peering_ingress_azure_gre" {
  type              = "ingress"
  ip_protocol       = "gre"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.peering_sg.id
  cidr_ip           = "70.153.184.179/32"
  description       = "GRE Tunnel from Azure CHR Public IP"
}

# Security Group 2: Dedicated for Secondary Interface (Private Subnet)
resource "alicloud_security_group" "private_sg" {
  security_group_name = "${var.instance_name}-private-sg"
  vpc_id              = var.vpc_id
  resource_group_id   = var.resource_group_id
  description         = "Dedicated Security Group for ${var.instance_name} secondary private interface"

  tags = {
    Name        = "${var.instance_name}-private-sg"
    Environment = "Production"
    Project     = "nextops"
    Tier        = "private"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "nextops"
  }
}

# Allow all internal VPC traffic on the private interface
resource "alicloud_security_group_rule" "private_ingress_internal_vpc" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.private_sg.id
  cidr_ip           = "10.151.64.0/18"
  description       = "Allow internal VPC traffic on private ENI"
}

# Allow GCP VPC traffic on the private interface (forwarded via CHR)
resource "alicloud_security_group_rule" "private_ingress_gcp_vpc" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.private_sg.id
  cidr_ip           = "10.101.0.0/16"
  description       = "Allow GCP Shared VPC traffic on private ENI"
}

# Allow Azure VNet traffic on the private interface
resource "alicloud_security_group_rule" "private_ingress_azure_vnet" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.private_sg.id
  cidr_ip           = var.azure_vnet_cidr
  description       = "Allow Azure VNet traffic on private ENI"
}

# Allow Spoke VPC (nextops-vpc) traffic on the private interface
resource "alicloud_security_group_rule" "private_ingress_spoke_vpc" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.private_sg.id
  cidr_ip           = var.spoke_vpc_cidr
  description       = "Allow Spoke VPC nextops-vpc traffic on private ENI"
}

##############################################################################
# Compute Instance: MikroTik CHR
##############################################################################

resource "alicloud_instance" "chr" {
  instance_name        = var.instance_name
  host_name            = var.instance_name
  image_id             = var.image_id
  instance_type        = var.instance_type
  availability_zone    = var.zone_id
  security_groups      = [alicloud_security_group.peering_sg.id]
  vswitch_id           = var.peering_vswitch_id
  instance_charge_type = "PostPaid"
  resource_group_id    = var.resource_group_id
  system_disk_category = var.system_disk_category
  system_disk_size     = var.system_disk_size
  private_ip           = var.peering_private_ip

  # Strictly zero public bandwidth directly on instance (uses EIP)
  internet_max_bandwidth_out = 0

  # Disable Source/Destination Check for NVA / NAT router function on primary interface
  source_dest_check = false

  lifecycle {
    ignore_changes = [password, image_id]
  }

  tags = {
    Name        = var.instance_name
    Environment = "Production"
    Project     = "nextops"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "nextops"
  }
}

##############################################################################
# Static Public IP (Elastic IP) attached to Primary Interface
##############################################################################

resource "alicloud_eip_address" "chr_eip" {
  address_name         = "${var.instance_name}-eip"
  internet_charge_type = "PayByTraffic"
  bandwidth            = var.eip_bandwidth
  resource_group_id    = var.resource_group_id
  payment_type         = "PayAsYouGo"

  tags = {
    Name        = "${var.instance_name}-eip"
    Environment = "Production"
    Project     = "nextops"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "nextops"
  }
}

resource "alicloud_eip_association" "chr_eip_assoc" {
  allocation_id = alicloud_eip_address.chr_eip.id
  instance_id   = alicloud_instance.chr.id
  instance_type = "EcsInstance"
}

##############################################################################
# Secondary Network Interface (Private Subnet 5a)
##############################################################################

resource "alicloud_ecs_network_interface" "private_eni" {
  network_interface_name = "${var.instance_name}-private-eni"
  vswitch_id             = var.private_vswitch_id
  security_group_ids     = [alicloud_security_group.private_sg.id]
  description            = "CHR secondary private-side ENI"
  resource_group_id      = var.resource_group_id
  primary_ip_address     = var.private_eni_ip

  tags = {
    Name        = "${var.instance_name}-private-eni"
    Environment = "Production"
    Project     = "nextops"
    Tier        = "private"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "nextops"
  }
}

resource "alicloud_ecs_network_interface_attachment" "private_eni_attach" {
  network_interface_id = alicloud_ecs_network_interface.private_eni.id
  instance_id          = alicloud_instance.chr.id
}
