output "instance_id" {
  value       = alicloud_instance.test_vm.id
  description = "The ID of the private test instance"
}

output "private_ip" {
  value       = alicloud_instance.test_vm.private_ip
  description = "The private IP address of the test instance"
}

output "instance_name" {
  value       = alicloud_instance.test_vm.instance_name
  description = "The name of the test instance"
}
