resource "oci_network_load_balancer_network_load_balancer" "ingress" {
  compartment_id = var.compartment_ocid
  display_name   = "k3s-ingress-nlb"
  subnet_id      = module.network.public_subnet_id
  is_private     = false

  network_security_group_ids = [module.security.nlb_nsg_id]
}

resource "oci_network_load_balancer_backend_set" "ingress" {
  for_each = local.ingress_listener_to_nodeport

  name                     = "ingress-${each.key}-bs"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol = "TCP"
    port     = each.value.node_port
  }
}

resource "oci_network_load_balancer_listener" "ingress" {
  for_each = local.ingress_listener_to_nodeport

  name                     = "ingress-${each.key}-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  port                     = each.value.listener_port
  protocol                 = "TCP"
  default_backend_set_name = oci_network_load_balancer_backend_set.ingress[each.key].name
}

resource "oci_network_load_balancer_backend" "ingress" {
  for_each = local.ingress_backend_targets

  backend_set_name         = oci_network_load_balancer_backend_set.ingress[each.value.backend_set_key].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  ip_address               = each.value.ip_address
  port                     = each.value.node_port
}
