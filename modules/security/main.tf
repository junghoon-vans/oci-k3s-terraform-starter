resource "oci_core_network_security_group" "k3s" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "k3s-nsg"
}

resource "oci_core_network_security_group_security_rule" "k3s_ingress_6443_node_to_node" {
  network_security_group_id = oci_core_network_security_group.k3s.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.k3s.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k3s_ingress_8472_node_to_node" {
  network_security_group_id = oci_core_network_security_group.k3s.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = oci_core_network_security_group.k3s.id
  source_type               = "NETWORK_SECURITY_GROUP"

  udp_options {
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k3s_ingress_10250_node_to_node" {
  count = var.enable_kubelet_port ? 1 : 0

  network_security_group_id = oci_core_network_security_group.k3s.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.k3s.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k3s_egress_all" {
  network_security_group_id = oci_core_network_security_group.k3s.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group" "nlb" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "k3s-ingress-nlb-nsg"
}

resource "oci_core_network_security_group_security_rule" "nlb_ingress_tcp" {
  for_each = toset([for port in var.nlb_listener_ports : tostring(port)])

  network_security_group_id = oci_core_network_security_group.nlb.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nlb_egress_to_k3s_nodeports" {
  for_each = toset([for port in var.ingress_nodeports : tostring(port)])

  network_security_group_id = oci_core_network_security_group.nlb.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.k3s.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k3s_ingress_from_nlb_nodeports" {
  for_each = toset([for port in var.ingress_nodeports : tostring(port)])

  network_security_group_id = oci_core_network_security_group.k3s.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.nlb.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}
