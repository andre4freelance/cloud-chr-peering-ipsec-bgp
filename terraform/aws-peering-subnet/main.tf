provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_subnet" "peering_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name        = var.subnet_name
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}

resource "aws_route_table_association" "peering_rta" {
  subnet_id      = aws_subnet.peering_subnet.id
  route_table_id = var.route_table_id
}
