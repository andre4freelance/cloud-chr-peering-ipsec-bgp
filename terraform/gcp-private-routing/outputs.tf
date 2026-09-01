output "route_to_aliyun_id" {
  description = "The ID of the route to Alibaba Cloud"
  value       = google_compute_route.route_to_aliyun.id
}

output "route_to_azure_id" {
  description = "The ID of the route to Azure"
  value       = google_compute_route.route_to_azure.id
}

output "next_hop_chr_private_ip" {
  description = "The Next Hop IP (CHR nic1 private interface)"
  value       = var.chr_workload_nic_ip
}
