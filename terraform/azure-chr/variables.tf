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

variable "compute_resource_group_name" {
  type        = string
  description = "Resource Group for VM and Disk resources"
  default     = "rg-nextops-compute"
}

variable "network_resource_group_name" {
  type        = string
  description = "Resource Group for VNet, Subnet, NIC, NSG, and Public IP"
  default     = "rg-nextops-network"
}

variable "security_resource_group_name" {
  type        = string
  description = "Resource Group for Key Vault and Disk Encryption Set"
  default     = "rg-nextops-security"
}

variable "vm_name" {
  type        = string
  description = "Name of the MikroTik CHR VM"
  default     = "chr-peering"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM (dual-NIC enabled)"
  default     = "Standard_D2as_v4"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the Virtual Network"
  default     = "vnet-nextops"
}

variable "peering_subnet_name" {
  type        = string
  description = "Name of the peering/WAN subnet"
  default     = "subnet-peering"
}

variable "peering_private_ip" {
  type        = string
  description = "Static private IP for the peering NIC"
  default     = "10.126.63.250"
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private/LAN subnet"
  default     = "subnet-private"
}

variable "private_private_ip" {
  type        = string
  description = "Static private IP for the private NIC"
  default     = "10.126.1.100"
}

variable "admin_source_ip_prefixes" {
  type        = list(string)
  description = "Allowed IP prefixes for management access (SSH, Winbox)"
  default     = ["103.165.198.50/32"]
}

variable "gcp_chr_public_ip" {
  type        = string
  description = "GCP CHR Public IP"
  default     = "34.101.118.166"
}

variable "aliyun_chr_public_ip" {
  type        = string
  description = "Alibaba Cloud CHR Public EIP"
  default     = "8.215.24.90"
}

variable "aws_chr_public_ip" {
  type        = string
  description = "AWS CHR Public Elastic IP"
  default     = "52.76.246.237"
}

variable "disk_encryption_set_name" {
  type        = string
  description = "Name of the Disk Encryption Set for CMK"
  default     = "des-nextops"
}

variable "custom_image_name" {
  type        = string
  description = "Name of the custom MikroTik CHR managed image"
  default     = "image-mikrotik-chr-7-24-1"
}
