variable "region" {
  type        = string
  description = "Huawei Cloud Region"
  default     = "ap-southeast-4"
}

variable "access_key" {
  type        = string
  description = "Huawei Cloud Access Key (AK)"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "Huawei Cloud Secret Key (SK)"
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  description = "ID of the target VPC (vpc-ics-nextops)"
  default     = "5942d1bc-b715-41cf-8f65-cc7634d07f8c"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the peering subnet (/28 at the end of 10.64.0.0/18 block)"
  default     = "10.64.63.240/28"
}

variable "gateway_ip" {
  type        = string
  description = "Gateway IP for the peering subnet"
  default     = "10.64.63.241"
}

variable "availability_zone" {
  type        = string
  description = "Availability Zone for the peering subnet"
  default     = "ap-southeast-4a"
}

variable "subnet_name" {
  type        = string
  description = "Name tag for the peering subnet"
  default     = "subnet-ics-nextops-peering-a"
}

variable "route_table_name" {
  type        = string
  description = "Name of the isolated route table"
  default     = "rtb-ics-nextops-peering"
}

variable "dns_list" {
  type        = list(string)
  description = "DNS resolvers for Huawei Cloud Jakarta"
  default     = ["100.125.1.250", "100.125.128.250"]
}
