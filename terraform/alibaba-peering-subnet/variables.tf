variable "profile" {
  type        = string
  description = "The profile name from aliyun configure"
  default     = "default"
}

variable "region" {
  type        = string
  description = "The Alibaba Cloud region ID"
  default     = "ap-southeast-5"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to create the vSwitch in (nextops-vpc)"
  default     = "vpc-k1anthliklw7pupgd2bx9"
}

variable "zone_id" {
  type        = string
  description = "The Availability Zone ID"
  default     = "ap-southeast-5a"
}

variable "cidr_block" {
  type        = string
  description = "The CIDR block for the peering vSwitch (/28 at the end of 10.151.0.0/18 block)"
  default     = "10.151.63.240/28"
}

variable "vswitch_name" {
  type        = string
  description = "The name of the vSwitch"
  default     = "nextops-peering-ap-southeast-5a"
}

variable "resource_group_id" {
  type        = string
  description = "The Resource Group ID (ics-nextops-production)"
  default     = "rg-aek46fmc2ohclmi"
}
