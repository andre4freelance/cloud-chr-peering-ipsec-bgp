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

variable "zone_id" {
  type        = string
  default     = "ap-southeast-5a"
  description = "Availability zone"
}

variable "resource_group_id" {
  type        = string
  default     = "rg-aek3jxlnulgvj3i"
  description = "Target Resource Group ID"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-k1ap3ij7ik4wgypdc1s5g"
  description = "VPC ID"
}

variable "private_vswitch_id" {
  type        = string
  default     = "vsw-k1as2atxwl1v5ls0bsgs3"
  description = "Private vSwitch ID (10.151.74.0/24)"
}

variable "private_security_group_id" {
  type        = string
  default     = "sg-k1a4f91v9g26jt4rzn00"
  description = "Private Subnet Security Group ID"
}

variable "instance_name" {
  type        = string
  default     = "managedservice-test-ubuntu"
  description = "Instance name"
}

variable "instance_type" {
  type        = string
  default     = "ecs.t6-c1m1.large"
  description = "Instance type (2 vCPU, 1 GB RAM)"
}

variable "image_id" {
  type        = string
  default     = "ubuntu_24_04_x64_20G_alibase_20260810.vhd"
  description = "Ubuntu 24.04 LTS 64-bit Image ID"
}

variable "key_name" {
  type        = string
  default     = "managedservice-test-key"
  description = "SSH Key Pair name"
}

variable "system_disk_category" {
  type        = string
  default     = "cloud_essd"
  description = "System disk category"
}

variable "system_disk_size" {
  type        = number
  default     = 20
  description = "System disk size in GB"
}
