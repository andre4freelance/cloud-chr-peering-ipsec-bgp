##############################################################################
# GCP MikroTik CHR Dual-NIC & VPC Setup
##############################################################################

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# Subnet 1: Peering Subnet (Primary NIC with Static Public IP)
resource "google_compute_subnetwork" "peering_subnet" {
  name          = "${var.vpc_name}-peering-subnet"
  ip_cidr_range = var.peering_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Subnet 2: Workload / Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.vpc_name}-private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Static External IP for GCP CHR
resource "google_compute_address" "chr_static_ip" {
  name   = "${var.instance_name}-static-ip"
  region = var.region
}

# Firewall: Management (SSH & Winbox from Admin IP)
resource "google_compute_firewall" "allow_admin_mgmt" {
  name    = "${var.instance_name}-allow-mgmt"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8291"]
  }

  source_ranges = [var.admin_ip_cidr]
  target_tags   = ["mikrotik-chr"]
}

# Firewall: IPsec & NAT-T from Alibaba CHR EIP
resource "google_compute_firewall" "allow_ipsec" {
  name    = "${var.instance_name}-allow-ipsec"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  source_ranges = ["0.0.0.0/0"] # Can be restricted to Alibaba CHR EIP
  target_tags   = ["mikrotik-chr"]
}

# Firewall: Internal VPC Traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.instance_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.peering_subnet_cidr, var.private_subnet_cidr, "10.151.64.0/18"]
}

# MikroTik CHR Compute Instance (Dual-NIC)
resource "google_compute_instance" "chr" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  can_ip_forward = true
  tags           = ["mikrotik-chr"]

  boot_disk {
    initialize_params {
      image = var.chr_custom_image
      size  = 20
      type  = "pd-standard"
    }
  }

  # Primary NIC (Peering Subnet + Public IP)
  network_interface {
    subnetwork = google_compute_subnetwork.peering_subnet.id
    network_ip = cidrhost(var.peering_subnet_cidr, 10) # e.g. 10.160.0.10

    access_config {
      nat_ip = google_compute_address.chr_static_ip.address
    }
  }

  # Secondary NIC (Workload Subnet)
  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    network_ip = cidrhost(var.private_subnet_cidr, 100) # e.g. 10.160.10.100
  }
}
