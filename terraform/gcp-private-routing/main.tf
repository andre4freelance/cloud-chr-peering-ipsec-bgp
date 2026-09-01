data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.project_id
}

# ==============================================================================
# ROUTING GCP SHARED VPC KE ALIBABA CLOUD & AZURE
# ==============================================================================
# Di GCP VPC, custom static route menggunakan next_hop_ip yang mengarah ke
# Private / Workload Interface CHR (nic1: 10.101.0.10).
# Subnet peering (10.101.16.0/28) tidak terpengaruh karena traffic lokal subnet
# memiliki prioritas connected (0) yang lebih tinggi dari custom route (800).

resource "google_compute_route" "route_to_aliyun" {
  name        = "rt-nextops-to-aliyun-via-chr"
  dest_range  = var.aliyun_vpc_cidr
  network     = data.google_compute_network.vpc.name
  project     = var.project_id
  next_hop_ip = var.chr_workload_nic_ip
  priority    = var.route_priority
  description = "Route to Alibaba Cloud VPC via MikroTik CHR private interface (nic1)"
}

resource "google_compute_route" "route_to_azure" {
  name        = "rt-nextops-to-azure-via-chr"
  dest_range  = var.azure_vnet_cidr
  network     = data.google_compute_network.vpc.name
  project     = var.project_id
  next_hop_ip = var.chr_workload_nic_ip
  priority    = var.route_priority
  description = "Route to Azure VNet via MikroTik CHR private interface (nic1)"
}
