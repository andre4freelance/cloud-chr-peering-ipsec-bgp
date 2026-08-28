output "instance_name" {
  description = "GCP MikroTik CHR instance name"
  value       = google_compute_instance.chr.name
}

output "public_ip" {
  description = "Dedicated Static Public IP for GCP CHR (nic0)"
  value       = google_compute_address.chr_static_ip.address
}

output "primary_nic0_private_ip" {
  description = "Static Private IP on peering subnet (nic0)"
  value       = google_compute_instance.chr.network_interface[0].network_ip
}

output "secondary_nic1_private_ip" {
  description = "Static Private IP on workload subnet (nic1)"
  value       = google_compute_instance.chr.network_interface[1].network_ip
}

output "winbox_connect_command" {
  description = "Connection string for Winbox"
  value       = "Connect to: ${google_compute_address.chr_static_ip.address}:8291"
}

output "ssh_connect_command" {
  description = "Connection command for SSH"
  value       = "ssh admin@${google_compute_address.chr_static_ip.address}"
}
