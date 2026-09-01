##############################################################################
# GCP MikroTik CHR Dual-NIC Deployment
# Model: Multi-Cloud Interconnect Mesh (Alibaba Cloud <-> GCP <-> Azure)
##############################################################################

# Reference to existing Shared VPC and Subnets in nextops-host
data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.project_id
}

data "google_compute_subnetwork" "peering_subnet" {
  name    = var.peering_subnet_name
  region  = var.region
  project = var.project_id
}

data "google_compute_subnetwork" "workload_subnet" {
  name    = var.workload_subnet_name
  region  = var.region
  project = var.project_id
}

# 1. Static Regional Public IP for Primary Interface (nic0)
resource "google_compute_address" "chr_static_ip" {
  name        = var.static_ip_name
  region      = var.region
  project     = var.project_id
  description = "Dedicated Static Public IP for gcp-chr-peering primary peering interface"

  lifecycle {
    prevent_destroy = true
  }
}

##############################################################################
# Dedicated Firewall Rules (Mimicking Dual Dedicated Security Groups)
# Interface 1 (nic0 / Peering / Public-facing): Tag "gcp-chr-peering-nic0"
# Interface 2 (nic1 / Workload / Internal):     Tag "gcp-chr-workload-nic1"
##############################################################################

# --- Dedicated Firewall for Interface 1 (nic0: Peering / Public-facing) ---

# Allow SSH (Port 22) and Winbox (Port 8291) from Admin IPs
resource "google_compute_firewall" "nic0_allow_mgmt" {
  name        = "${var.instance_name}-nic0-allow-mgmt"
  network     = data.google_compute_network.vpc.name
  project     = var.project_id
  description = "Dedicated nic0: Allow SSH and Winbox management from Admin IPs"

  allow {
    protocol = "tcp"
    ports    = ["22", "8291"]
  }

  source_ranges = var.admin_ip_cidrs
  target_tags   = ["gcp-chr-peering-nic0"]
}

# Allow IPsec IKEv2 (UDP 500), NAT-T (UDP 4500), and GRE (47) from Alibaba & Azure CHR Public IPs
resource "google_compute_firewall" "nic0_allow_ipsec" {
  name        = "${var.instance_name}-nic0-allow-ipsec"
  network     = data.google_compute_network.vpc.name
  project     = var.project_id
  description = "Dedicated nic0: Allow IPsec, NAT-T, and GRE from Alibaba and Azure CHR Public IPs"

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  allow {
    protocol = "47"
  }

  source_ranges = [
    "${var.alibaba_chr_public_ip}/32",
    "${var.azure_chr_public_ip}/32"
  ]
  target_tags = ["gcp-chr-peering-nic0"]
}

# --- Dedicated Firewall for Interface 2 (nic1: Workload / Internal VPC) ---

# Allow all internal VPC traffic, Alibaba Cloud VPC, and Azure VNet traffic on private interface
resource "google_compute_firewall" "nic1_allow_internal_vpc" {
  name        = "${var.instance_name}-nic1-allow-internal-vpc"
  network     = data.google_compute_network.vpc.name
  project     = var.project_id
  description = "Dedicated nic1: Allow internal VPC, Alibaba VPC, and Azure VNet traffic"

  allow {
    protocol = "all"
  }

  source_ranges = [
    "10.101.0.0/16",      # Entire GCP Shared VPC Supernet
    var.alibaba_vpc_cidr, # Alibaba Cloud VPC Subnet (10.151.64.0/18)
    var.azure_vnet_cidr   # Azure VNet Subnet (10.126.0.0/18)
  ]
  target_tags = ["gcp-chr-workload-nic1"]
}

##############################################################################
# MikroTik CHR Compute Instance (Dual-NIC with Static Private & Public IPs)
##############################################################################

resource "google_compute_instance" "chr" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  description  = "MikroTik CHR Router for Multi-Cloud Hybrid Interconnect"

  can_ip_forward = true

  # Network tags representing the dedicated firewall policies for both interfaces
  tags = [
    "gcp-chr-peering-nic0",
    "gcp-chr-workload-nic1"
  ]

  boot_disk {
    initialize_params {
      image = var.chr_custom_image
      size  = 10
      type  = "pd-standard"
    }
  }

  # Primary NIC (nic0): Dedicated Peering Subnet + Static Private IP + Static Public IP
  network_interface {
    subnetwork = data.google_compute_subnetwork.peering_subnet.id
    network_ip = var.peering_nic_ip

    access_config {
      nat_ip = google_compute_address.chr_static_ip.address
    }
  }

  # Secondary NIC (nic1): Dedicated Workload Subnet + Static Private IP
  network_interface {
    subnetwork = data.google_compute_subnetwork.workload_subnet.id
    network_ip = var.workload_nic_ip
  }

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}
