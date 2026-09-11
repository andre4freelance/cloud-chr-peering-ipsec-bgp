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
  description = "Resource Group ID (ics-managed-service)"
  type        = string
  default     = "rg-aek3jxlnulgvj3i"
}

variable "vpc_id" {
  description = "VPC ID where the instance resides (managedservice-vpc)"
  type        = string
  default     = "vpc-k1ap3ij7ik4wgypdc1s5g"
}

variable "peering_vswitch_id" {
  description = "vSwitch ID for Primary Interface (managedservice-peering-ap-southeast-5a)"
  type        = string
  default     = "vsw-k1agelkxe91ul5aj95i9p"
}

variable "private_vswitch_id" {
  description = "vSwitch ID for Secondary Interface (managedservice-private-ap-southeast-5a)"
  type        = string
  default     = "vsw-k1as2atxwl1v5ls0bsgs3"
}

variable "instance_name" {
  description = "Name tag and hostname of the instance"
  type        = string
  default     = "chr-peering-ms"
}

variable "image_id" {
  description = "Custom MikroTik CHR image ID (x86_64, legacy BIOS)"
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

variable "eip_bandwidth" {
  description = "Maximum bandwidth for Elastic IP in Mbps (PayByTraffic)"
  type        = number
  default     = 100
}

variable "nextops_chr_public_ip" {
  description = "Alibaba Cloud NextOps CHR Public IP for direct IPsec/GRE peering"
  type        = string
  default     = "8.215.24.90"
}

variable "admin_ip_cidr" {
  description = "Admin source IP CIDR for SSH and Winbox whitelist (0.0.0.0/0 for hardened ports)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_port" {
  description = "Custom hardened SSH Port"
  type        = number
  default     = 7822
}

variable "winbox_port" {
  description = "Custom hardened Winbox Port"
  type        = number
  default     = 7881
}
