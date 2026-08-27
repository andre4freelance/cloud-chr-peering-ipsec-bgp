output "instance_name" {
  description = "GCP MikroTik CHR instance name"
  value       = google_compute_instance.chr.name
}

output "public_ip" {
  description = "Static Public IP of GCP CHR"
  value       = google_compute_address.chr_static_ip.address
}

output "primary_private_ip" {
  description = "Private IP on primary peering subnet"
  value       = google_compute_instance.chr.network_interface[0].network_ip
}

output "secondary_private_ip" {
  description = "Private IP on workload private subnet"
  value       = google_compute_instance.chr.network_interface[1].network_ip
}
