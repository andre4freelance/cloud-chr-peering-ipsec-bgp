variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID"
  default     = "98550686-a6be-4949-8878-e2d13d8a8084"
}

variable "location" {
  type        = string
  description = "Azure Region Location"
  default     = "indonesiacentral"
}

variable "network_resource_group_name" {
  type        = string
  description = "Resource Group containing the Virtual Network and Subnets"
  default     = "rg-nextops-network"
}

variable "virtual_network_name" {
  type        = string
  description = "Virtual Network Name"
  default     = "vnet-nextops"
}

variable "chr_private_ip" {
  type        = string
  description = "Private IP of chr-peering LAN interface (NIC 1 / eth1) as Next Hop"
  default     = "10.126.1.100"
}

variable "aliyun_vpc_cidr" {
  type        = string
  description = "Alibaba Cloud VPC Supernet CIDR (Hub managedservice-vpc)"
  default     = "10.151.64.0/18"
}

variable "aliyun_spoke_vpc_cidr" {
  type        = string
  description = "Alibaba Cloud Spoke VPC CIDR (Production nextops-vpc)"
  default     = "10.151.0.0/18"
}

variable "gcp_vpc_cidr" {
  type        = string
  description = "GCP VPC Supernet CIDR"
  default     = "10.101.0.0/16"
}
