variable "profile" {
  type        = string
  default     = "default"
  description = "Aliyun CLI profile name (~/.aliyun/config.json)"
}

variable "region" {
  type        = string
  default     = "ap-southeast-5"
  description = "Aliyun region"
}

# --- Hub VPC (managedservice-vpc) ---
variable "hub_vpc_id" {
  type        = string
  default     = "vpc-k1ap3ij7ik4wgypdc1s5g"
  description = "VPC ID of managedservice-vpc (Hub / CHR Peering)"
}

variable "hub_vpc_cidr" {
  type        = string
  default     = "10.151.64.0/18"
  description = "CIDR of managedservice-vpc"
}

variable "hub_resource_group_id" {
  type        = string
  default     = "rg-aek3jxlnulgvj3i"
  description = "Resource Group ID for managedservice-vpc"
}

# --- Spoke / Production VPC (nextops-vpc) ---
variable "spoke_vpc_id" {
  type        = string
  default     = "vpc-k1anthliklw7pupgd2bx9"
  description = "VPC ID of nextops-vpc (Production / Spoke)"
}

variable "spoke_vpc_cidr" {
  type        = string
  default     = "10.151.0.0/18"
  description = "CIDR of nextops-vpc"
}

variable "spoke_resource_group_id" {
  type        = string
  default     = "rg-aek46fmc2ohclmi"
  description = "Resource Group ID for nextops-vpc"
}

# --- Route Table IDs in Hub VPC ---
variable "hub_private_route_table_id" {
  type        = string
  default     = "vtb-k1a0826dm2o2rfbhe7rcv"
  description = "Custom private route table in managedservice-vpc"
}

variable "hub_public_route_table_id" {
  type        = string
  default     = "vtb-k1aqcxlbr5xul3w2z69px"
  description = "Custom public route table in managedservice-vpc"
}

variable "hub_system_route_table_id" {
  type        = string
  default     = "vtb-k1aupjjbqx8lkiu9s3g7a"
  description = "System route table in managedservice-vpc (covers peering subnet)"
}

# --- Route Table IDs in Spoke VPC ---
variable "spoke_system_route_table_id" {
  type        = string
  default     = "vtb-k1ap8dipbm7u58azmsgrj"
  description = "System route table in nextops-vpc (covers all public & private subnets)"
}

# --- Multi-Cloud CIDRs ---
variable "gcp_vpc_cidr" {
  type        = string
  default     = "10.101.0.0/18"
  description = "CIDR block of Google Cloud Platform (GCP) VPC"
}

variable "azure_vnet_cidr" {
  type        = string
  default     = "10.126.0.0/18"
  description = "CIDR block of Microsoft Azure VNet"
}
