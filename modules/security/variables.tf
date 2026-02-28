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
