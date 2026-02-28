locals {
  k3s_names = ["k3s-node-1", "k3s-node-2", "k3s-node-3"]
}

output "bastion_public_ip" {
  value = module.compute.public_ips["bastion-1"]
}

output "bastion_private_ip" {
  value = module.compute.private_ips["bastion-1"]
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
    public  = module.network.public_subnet_id
    private = module.network.private_subnet_id
  }
}
