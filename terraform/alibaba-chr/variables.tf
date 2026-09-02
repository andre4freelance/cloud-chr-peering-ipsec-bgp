variable "profile" {
  description = "Profile name from aliyun configure (~/.aliyun/config.json)"
  type        = string
  default     = "default"
}

variable "region" {
  description = "Alibaba Cloud Region ID"
  type        = string
  default     = "ap-southeast-5"
}

variable "zone_id" {
  description = "Availability Zone ID for instance and vSwitches"
  type        = string
  default     = "ap-southeast-5a"
}

variable "resource_group_id" {
  description = "Resource Group ID"
  type        = string
  default     = "rg-aek3jxlnulgvj3i"
}

variable "vpc_id" {
  description = "VPC ID where the instance resides"
  type        = string
  default     = "vpc-k1ap3ij7ik4wgypdc1s5g"
}

variable "peering_vswitch_id" {
  description = "vSwitch ID for Primary Interface (Peering subnet)"
  type        = string
  default     = "vsw-k1agelkxe91ul5aj95i9p"
}

variable "private_vswitch_id" {
  description = "vSwitch ID for Secondary Interface (Private subnet 5a)"
  type        = string
  default     = "vsw-k1as2atxwl1v5ls0bsgs3"
}

variable "instance_name" {
  description = "Name tag and hostname of the instance"
  type        = string
  default     = "chr-peering"
}

variable "image_id" {
  description = "Custom MikroTik CHR image ID (x86_64)"
  type        = string
  default     = "m-k1aaa7o07ybfhrzg687t"
}

variable "instance_type" {
  description = "ECS Instance Type supporting Dual-NIC"
  type        = string
  default     = "ecs.t6-c1m1.large"
}

variable "system_disk_category" {
  description = "Category of system disk"
  type        = string
  default     = "cloud_efficiency"
}

variable "system_disk_size" {
  description = "Size of system disk in GB"
  type        = number
  default     = 20
}

variable "peering_private_ip" {
  description = "Static private IP on the primary peering interface"
  type        = string
  default     = "10.151.127.250"
}

variable "private_eni_ip" {
  description = "Static private IP on the secondary private interface"
  type        = string
  default     = "10.151.74.100"
}

variable "admin_ip_cidr" {
  description = "Admin source IP CIDR for SSH and Winbox whitelist"
  type        = string
  default     = "103.94.10.189/32"
}

variable "gcp_chr_public_ip" {
  description = "GCP CHR Static Public IP for IPsec peering"
  type        = string
  default     = "34.101.118.166"
}

variable "ssh_port" {
  description = "Port number for SSH"
  type        = number
  default     = 22
}

variable "winbox_port" {
  description = "Port number for MikroTik Winbox"
  type        = number
  default     = 8291
}

variable "azure_vnet_cidr" {
  description = "Azure VNet CIDR block"
  type        = string
  default     = "10.126.0.0/18"
}

variable "spoke_vpc_cidr" {
  description = "Spoke Production VPC nextops-vpc CIDR block"
  type        = string
  default     = "10.151.0.0/18"
}

variable "eip_bandwidth" {
  description = "Peak bandwidth limit in Mbps for EIP (PayByTraffic)"
  type        = string
  default     = "100"
}
