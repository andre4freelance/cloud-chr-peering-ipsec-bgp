variable "project_id" {
  type        = string
  description = "The GCP Project ID"
  default     = "nextops-host"
}

variable "region" {
  type        = string
  description = "The GCP Region"
  default     = "asia-southeast2"
}

variable "vpc_name" {
  type        = string
  description = "VPC network name in GCP"
  default     = "nextops-shared-vpc"
}

variable "chr_instance_name" {
  type        = string
  description = "Name of the MikroTik CHR instance in GCP"
  default     = "chr-peering"
}

variable "chr_workload_nic_ip" {
  type        = string
  description = "Static internal IP for CHR secondary workload/private interface (nic1)"
  default     = "10.101.0.10"
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

variable "azure_vnet_cidr" {
  type        = string
  description = "Microsoft Azure VNet Supernet CIDR"
  default     = "10.126.0.0/18"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "Amazon Web Services (AWS) VPC Supernet CIDR"
  default     = "10.29.0.0/18"
}

variable "route_priority" {
  type        = number
  description = "Priority for the custom static routes"
  default     = 800
}
