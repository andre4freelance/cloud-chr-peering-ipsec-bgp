variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI Profile"
  default     = "ics-ms-andre"
}

variable "vpc_id" {
  type        = string
  description = "ID of the target VPC"
  default     = "vpc-0536e350d0c6f6f2c"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the peering subnet"
  default     = "10.29.63.240/28"
}

variable "availability_zone" {
  type        = string
  description = "Availability Zone for the subnet"
  default     = "ap-southeast-1a"
}

variable "subnet_name" {
  type        = string
  description = "Name tag for the peering subnet"
  default     = "subnet-ics-nextops-peering-a"
}

variable "route_table_id" {
  type        = string
  description = "Route Table ID with IGW to associate"
  default     = "rtb-063dba72740af77e5"
}
