variable "compartment_ocid" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "enable_kubelet_port" {
  type    = bool
  default = true
}

variable "nlb_listener_ports" {
  type    = list(number)
  default = [80, 443]
}

variable "ingress_nodeports" {
  type    = list(number)
  default = [30080, 30443]
}
