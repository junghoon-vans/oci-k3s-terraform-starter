variable "compartment_ocid" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "ssh_authorized_keys" {
  type = string
}

variable "instances" {
  type = map(object({
    subnet_id               = string
    assign_public_ip        = bool
    private_ip              = string
    nsg_ids                 = list(string)
    role                    = string
    image_ocid              = string
    shape                   = string
    boot_volume_size_in_gbs = number
    ocpus                   = optional(number)
    memory_in_gbs           = optional(number)
    user_data_base64        = string
  }))
}
