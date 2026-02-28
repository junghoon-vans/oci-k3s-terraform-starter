output "instance_ids" {
  value = { for name, instance in oci_core_instance.this : name => instance.id }
}

output "private_ips" {
  value = { for name, vnic in data.oci_core_vnic.this : name => vnic.private_ip_address }
}

output "public_ips" {
  value = { for name, vnic in data.oci_core_vnic.this : name => try(vnic.public_ip_address, null) }
}
