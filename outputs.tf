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
    public  = module.network.public_subnet_id
  }
}

output "ingress_nlb" {
  value = {
    id        = oci_network_load_balancer_network_load_balancer.ingress.id
    public_ip = try(oci_network_load_balancer_network_load_balancer.ingress.ip_addresses[0].ip_address, null)
    listeners = {
      http  = var.ingress_listener_http_port
      https = var.ingress_listener_https_port
    }
    nodeports = {
      http  = var.ingress_nodeport_http
      https = var.ingress_nodeport_https
    }
  }
}
