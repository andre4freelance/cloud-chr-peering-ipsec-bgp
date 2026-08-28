##############################################################################
# Custom Route Table for Private vSwitch (managedservice-private-ap-southeast-5a)
# Routes 0.0.0.0/0 next-hop to MikroTik CHR secondary private ENI
##############################################################################

# 1. Custom Route Table bound to VSwitch
resource "alicloud_route_table" "private_rt" {
  vpc_id           = var.vpc_id
  route_table_name = var.route_table_name
  description      = "Custom route table routing egress traffic to MikroTik CHR private ENI"
  associate_type   = "VSwitch"

  tags = {
    Name        = var.route_table_name
    Environment = "ManagedService"
    Project     = "managedservice"
    Tier        = "private"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "managedservice"
  }
}

# 2. Attach Custom Route Table to Private vSwitch
resource "alicloud_route_table_attachment" "private_vswitch_attach" {
  vswitch_id     = var.private_vswitch_id
  route_table_id = alicloud_route_table.private_rt.id
}

# 3. Default Route (0.0.0.0/0) -> MikroTik CHR Private ENI
resource "alicloud_route_entry" "default_to_chr_eni" {
  route_table_id        = alicloud_route_table.private_rt.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "NetworkInterface"
  nexthop_id            = var.chr_private_eni_id
}
