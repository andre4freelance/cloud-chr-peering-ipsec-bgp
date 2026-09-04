resource "alicloud_vswitch" "peering_vswitch" {
  vpc_id       = var.vpc_id
  cidr_block   = var.cidr_block
  zone_id      = var.zone_id
  vswitch_name = var.vswitch_name

  tags = {
    Name        = var.vswitch_name
    Environment = "Production"
    Project     = "nextops"
    Tier        = "peering"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "nextops"
  }
}
