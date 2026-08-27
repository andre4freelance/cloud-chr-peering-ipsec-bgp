variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast2" # Jakarta
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-southeast2-a"
}

variable "vpc_name" {
  description = "VPC network name in GCP"
  type        = string
  default     = "gcp-hub-vpc"
}

variable "peering_subnet_cidr" {
  description = "CIDR for CHR primary/peering subnet"
  type        = string
  default     = "10.160.0.0/28"
}

variable "private_subnet_cidr" {
  description = "CIDR for GCP private workload subnet"
  type        = string
  default     = "10.160.10.0/24"
}

variable "instance_name" {
  description = "Name of the MikroTik CHR VM in GCP"
  type        = string
  default     = "gcp-chr-peering"
}

variable "machine_type" {
  description = "GCP Machine Type (e2-small or e2-medium)"
  type        = string
  default     = "e2-small"
}

variable "chr_custom_image" {
  description = "Custom MikroTik CHR image name/family in GCP"
  type        = string
  default     = "mikrotik-chr-7"
}

variable "admin_ip_cidr" {
  description = "Admin IP CIDR whitelist for SSH and Winbox"
  type        = string
  default     = "103.94.10.189/32"
}
