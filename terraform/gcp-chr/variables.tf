variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "nextops-host"
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
  default     = "nextops-shared-vpc"
}

variable "peering_subnet_name" {
  description = "Subnet name for CHR primary/peering interface (nic0)"
  type        = string
  default     = "nextops-peering-apse2-subnet"
}

variable "peering_nic_ip" {
  description = "Static internal IP for CHR primary peering NIC (nic0)"
  type        = string
  default     = "10.101.16.10"
}

variable "workload_subnet_name" {
  description = "Subnet name for CHR secondary/workload interface (nic1)"
  type        = string
  default     = "nextops-prod-apse2-subnet"
}

variable "workload_nic_ip" {
  description = "Static internal IP for CHR secondary workload NIC (nic1)"
  type        = string
  default     = "10.101.0.10"
}

variable "instance_name" {
  description = "Name of the MikroTik CHR VM in GCP"
  type        = string
  default     = "chr-peering"
}

# Pinned deliberately, NOT derived from instance_name.
# Renaming a google_compute_address destroys it and a new one gets a fresh
# random IP. 34.101.118.166 is hardcoded in the Alibaba security group and in
# the peer address of the Alibaba CHR IPsec config, so losing it means
# reconfiguring both sides. Keep the legacy name; the IP is what matters.
variable "static_ip_name" {
  description = "Name of the reserved regional address holding the CHR public IP"
  type        = string
  default     = "gcp-chr-peering-static-ip"
}

variable "machine_type" {
  description = "GCP Machine Type"
  type        = string
  default     = "e2-micro"
}

variable "chr_custom_image" {
  description = "Custom MikroTik CHR image name in GCP"
  type        = string
  default     = "mikrotik-chr-7-24-1"
}

variable "admin_ip_cidrs" {
  description = "Admin IP CIDR whitelist for SSH and Winbox management"
  type        = list(string)
  default = [
    "103.94.10.189/32",
    "103.165.198.50/32",
    "180.243.7.53/32", # workstation, dynamic ISP IP — refresh when Winbox starts timing out
  ]
}

variable "alibaba_chr_public_ip" {
  description = "Alibaba Cloud CHR Public EIP for IPsec peering"
  type        = string
  default     = "8.215.24.90"
}

variable "alibaba_vpc_cidr" {
  description = "Alibaba Cloud VPC CIDR block (Hub managedservice-vpc)"
  type        = string
  default     = "10.151.64.0/18"
}

variable "alibaba_spoke_vpc_cidr" {
  description = "Alibaba Cloud Spoke VPC CIDR block (Production nextops-vpc)"
  type        = string
  default     = "10.151.0.0/18"
}

variable "azure_vnet_cidr" {
  description = "Microsoft Azure VNet Supernet CIDR block"
  type        = string
  default     = "10.126.0.0/18"
}
