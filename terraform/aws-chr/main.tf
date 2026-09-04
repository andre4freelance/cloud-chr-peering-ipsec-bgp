provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# -----------------------------------------------------------------------------
# Security Group for CHR Peering (WAN / ether1)
# -----------------------------------------------------------------------------
resource "aws_security_group" "chr_peering_sg" {
  name        = "ics-nextops-chr-peering-sg"
  description = "Security group for MikroTik CHR Peering (WAN/ether1)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_allowed_cidr]
  }

  ingress {
    description = "Winbox from Admin"
    from_port   = 8291
    to_port     = 8291
    protocol    = "tcp"
    cidr_blocks = [var.admin_allowed_cidr]
  }

  ingress {
    description = "ICMP from Admin"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.admin_allowed_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-ics-nextops-chr-peering"
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}

# -----------------------------------------------------------------------------
# Security Group for CHR Private (LAN / ether2)
# -----------------------------------------------------------------------------
resource "aws_security_group" "chr_private_sg" {
  name        = "ics-nextops-chr-private-sg"
  description = "Security group for MikroTik CHR Internal Routing (LAN/ether2)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic from internal VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.29.0.0/18"]
  }

  ingress {
    description = "Allow multi-cloud supernets via LAN"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "10.151.0.0/18", # Alibaba NextOps
      "10.101.0.0/16", # GCP NextOps
      "10.126.0.0/18"  # Azure NextOps
    ]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-ics-nextops-chr-private"
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}

# -----------------------------------------------------------------------------
# Primary ENI (WAN / ether1)
# -----------------------------------------------------------------------------
resource "aws_network_interface" "chr_wan_eni" {
  subnet_id         = var.peering_subnet_id
  private_ips       = [var.peering_private_ip]
  security_groups   = [aws_security_group.chr_peering_sg.id]
  source_dest_check = false
  description       = "Primary WAN interface (ether1) for CHR Peering"

  tags = {
    Name        = "eni-chr-peering-wan"
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP (EIP) attached to Primary ENI
# -----------------------------------------------------------------------------
resource "aws_eip" "chr_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.chr_wan_eni.id

  tags = {
    Name        = "eip-ics-nextops-chr-peering"
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}

# -----------------------------------------------------------------------------
# Secondary ENI (LAN / ether2)
# -----------------------------------------------------------------------------
resource "aws_network_interface" "chr_lan_eni" {
  subnet_id         = var.private_subnet_id
  private_ips       = [var.lan_private_ip]
  security_groups   = [aws_security_group.chr_private_sg.id]
  source_dest_check = false
  description       = "Secondary LAN interface (ether2) for CHR Internal Transit"

  tags = {
    Name        = "eni-chr-peering-lan"
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance: MikroTik CHR
# -----------------------------------------------------------------------------
resource "aws_instance" "chr" {
  ami           = var.ami_id
  instance_type = var.instance_type

  network_interface {
    network_interface_id = aws_network_interface.chr_wan_eni.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.chr_lan_eni.id
    device_index         = 1
  }

  root_block_device {
    volume_size           = 1
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
    tags = {
      Name = "vol-chr-peering-root"
    }
  }

  tags = {
    Name        = var.instance_name
    Environment = "Production"
    Project     = "Nextops"
    Tier        = "peering"
    Owner       = "Managed Service"
    ManagedBy   = "Terraform"
    CostCenter  = "Nextops"
  }
}
