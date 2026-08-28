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

variable "private_vswitch_id" {
  type        = string
  default     = "vsw-k1as2atxwl1v5ls0bsgs3"
  description = "Private vSwitch ID (managedservice-private-ap-southeast-5a)"
}

variable "chr_private_eni_id" {
  type        = string
  default     = "eni-k1ahx623o3hwm5j97ubx"
  description = "Secondary ENI ID of MikroTik CHR in private subnet (10.151.74.100)"
}

variable "route_table_name" {
  type        = string
  default     = "managedservice-private-rt"
  description = "Custom route table name for private vSwitch"
}
