variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID"
  default     = "98550686-a6be-4949-8878-e2d13d8a8084"
}

variable "resource_group_name" {
  type        = string
  description = "The Resource Group containing the Virtual Network"
  default     = "rg-nextops-network"
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the Virtual Network"
  default     = "vnet-nextops"
}

variable "subnet_name" {
  type        = string
  description = "The name of the peering subnet"
  default     = "subnet-peering"
}

variable "address_prefixes" {
  type        = list(string)
  description = "The address prefixes for the peering subnet (/28 at the end of 10.126.0.0/18 block)"
  default     = ["10.126.63.240/28"]
}
