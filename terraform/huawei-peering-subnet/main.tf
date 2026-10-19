terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.60.0"
    }
  }
}

provider "huaweicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "huaweicloud_vpc_subnet" "peering_subnet" {
  name              = var.subnet_name
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone
  cidr              = var.cidr_block
  gateway_ip        = var.gateway_ip
  dns_list          = var.dns_list

  tags = {
    Name        = var.subnet_name
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Nextops"
    CostCenter  = "Nextops"
    ManagedBy   = "Terraform"
  }
}

resource "huaweicloud_vpc_route_table" "peering_rtb" {
  name        = var.route_table_name
  vpc_id      = var.vpc_id
  description = "Isolated route table for multi-cloud peering subnet (direct EIP egress)"

  subnets = [
    huaweicloud_vpc_subnet.peering_subnet.id,
  ]
}
