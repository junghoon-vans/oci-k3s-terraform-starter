locals {
  k3s_names = ["k3s-node-1", "k3s-node-2", "k3s-node-3", "k3s-node-4"]
}

output "k3s_private_ips" {
  value = [for name in local.k3s_names : module.compute.private_ips[name]]
}

output "instance_ocids" {
  value = values(module.compute.instance_ids)
}

output "vcn_id" {
  value = module.network.vcn_id
}

output "subnet_ids" {
  value = {
    private = module.network.private_subnet_id
  }
}
