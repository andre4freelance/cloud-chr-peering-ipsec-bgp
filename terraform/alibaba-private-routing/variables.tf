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

variable "vpc_id" {
  type        = string
  default     = "vpc-k1ap3ij7ik4wgypdc1s5g"
  description = "VPC ID (managedservice-vpc)"
}

variable "private_vswitch_ids" {
  type        = list(string)
  default     = ["vsw-k1as2atxwl1v5ls0bsgs3", "vsw-k1au00ub252b1sbej2twq"]
  description = "List of Private vSwitch IDs (Zone A & Zone B)"
}

variable "public_vswitch_ids" {
  type        = list(string)
  default     = ["vsw-k1a75msk15j30llpntp11", "vsw-k1a8d88b3c5ailyrafrht"]
  description = "List of Public vSwitch IDs (Zone A & Zone B)"
}

variable "chr_private_eni_id" {
  type        = string
  default     = "eni-k1ahx623o3hwm5j97ubx"
  description = "Secondary ENI ID of MikroTik CHR in private subnet (10.151.74.100)"
}

variable "private_route_table_name" {
  type        = string
  default     = "managedservice-private-rt"
  description = "Custom route table name for private vSwitches"
}

variable "public_route_table_name" {
  type        = string
  default     = "managedservice-public-rt"
  description = "Custom route table name for public vSwitches"
}

variable "gcp_vpc_cidr" {
  type        = string
  default     = "10.101.0.0/16"
  description = "CIDR block of Google Cloud Platform (GCP) VPC"
}

variable "azure_vnet_cidr" {
  type        = string
  default     = "10.126.0.0/18"
  description = "CIDR block of Microsoft Azure VNet"
}
