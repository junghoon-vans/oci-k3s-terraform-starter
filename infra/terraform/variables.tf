variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-seoul-1"
}

variable "compartment_ocid" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "ssh_authorized_keys" {
  type = string
}

variable "availability_domain" {
  type    = string
  default = null
}

variable "image_ocid" {
  type = string
}

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  type    = number
  default = 1
}

variable "memory_in_gbs" {
  type    = number
  default = 6
}

variable "boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "enable_kubelet_port" {
  type    = bool
  default = true
}

variable "vcn_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.10.0/24"
}
