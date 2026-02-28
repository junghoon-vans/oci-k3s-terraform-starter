variable "compartment_ocid" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "ssh_authorized_keys" {
  type = string
}

variable "image_ocid" {
  type = string
}

variable "shape" {
  type = string
}

variable "ocpus" {
  type = number
}

variable "memory_in_gbs" {
  type = number
}

variable "boot_volume_size_in_gbs" {
  type = number
}

variable "instances" {
  type = map(object({
    subnet_id        = string
    assign_public_ip = bool
    private_ip       = string
    nsg_ids          = list(string)
    role             = string
    user_data_base64 = string
  }))
}
