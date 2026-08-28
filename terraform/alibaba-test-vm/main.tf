##############################################################################
# Private Test VM in Aliyun (No Public IP / EIP)
# Egress to Internet and Cross-Cloud via MikroTik CHR NVA
##############################################################################

resource "alicloud_instance" "test_vm" {
  instance_name        = var.instance_name
  host_name            = var.instance_name
  image_id             = var.image_id
  instance_type        = var.instance_type
  availability_zone    = var.zone_id
  security_groups      = [var.private_security_group_id]
  vswitch_id           = var.private_vswitch_id
  instance_charge_type = "PostPaid"
  resource_group_id    = var.resource_group_id
  system_disk_category = var.system_disk_category
  system_disk_size     = var.system_disk_size
  key_name             = var.key_name

  # Strictly zero public bandwidth (no public IP / no EIP)
  internet_max_bandwidth_out = 0

  lifecycle {
    ignore_changes = [password, image_id]
  }

  tags = {
    Name        = var.instance_name
    Environment = "ManagedService"
    Project     = "managedservice"
    Tier        = "private"
    Owner       = "ics-ms"
    ManagedBy   = "terraform"
    CostCenter  = "managedservice"
  }
}
