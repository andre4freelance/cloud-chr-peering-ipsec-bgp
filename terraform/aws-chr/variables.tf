variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI Profile"
  default     = "ics-ms-andre"
}

variable "vpc_id" {
  type        = string
  description = "ID of the target VPC"
  default     = "vpc-0536e350d0c6f6f2c"
}

variable "ami_id" {
  type        = string
  description = "MikroTik CHR AMI ID"
  default     = "ami-0976e5ab018287374"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
  default     = "t3.medium"
}

variable "instance_name" {
  type        = string
  description = "Name tag for the CHR instance"
  default     = "chr-peering"
}

variable "peering_subnet_id" {
  type        = string
  description = "Subnet ID for WAN / ether1"
  default     = "subnet-0373d47e8d062e9fb" # subnet-ics-nextops-peering-a
}

variable "peering_private_ip" {
  type        = string
  description = "Static Private IP for WAN interface (ether1)"
  default     = "10.29.63.250"
}

variable "private_subnet_id" {
  type        = string
  description = "Subnet ID for LAN / ether2"
  default     = "subnet-06a9b7dfef9496a20" # subnet-ics-nextops-private-a
}

variable "lan_private_ip" {
  type        = string
  description = "Static Private IP for LAN interface (ether2)"
  default     = "10.29.16.100"
}

variable "admin_allowed_cidr" {
  type        = string
  description = "Current Client Public IP for SSH & Winbox management"
  default     = "36.69.87.159/32"
}
