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
