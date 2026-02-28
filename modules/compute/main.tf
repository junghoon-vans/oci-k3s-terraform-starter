data "oci_core_images" "ubuntu_2404_a1" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.shape
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  images_matching_build = [
    for image in data.oci_core_images.ubuntu_2404_a1.images : image
    if can(regex(var.ubuntu_image_build, try(image.display_name, ""))) || can(regex(var.ubuntu_image_build, try(image.name, "")))
  ]

  selected_image_id = coalesce(
    var.image_ocid,
    try(local.images_matching_build[0].id, null),
    try(data.oci_core_images.ubuntu_2404_a1.images[0].id, null)
  )
}

resource "oci_core_instance" "this" {
  for_each            = var.instances
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = each.key
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = each.value.subnet_id
    assign_public_ip = each.value.assign_public_ip
    nsg_ids          = each.value.nsg_ids
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
    k3s_role            = each.value.role
  }

  source_details {
    source_type             = "image"
    source_id               = local.selected_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  lifecycle {
    precondition {
      condition     = local.selected_image_id != null
      error_message = "No Ubuntu 24.04 A1 image found. Set image_ocid explicitly for this region/AD."
    }
  }
}

data "oci_core_vnic_attachments" "this" {
  for_each       = oci_core_instance.this
  compartment_id = var.compartment_ocid
  instance_id    = each.value.id
}

data "oci_core_vnic" "this" {
  for_each = data.oci_core_vnic_attachments.this
  vnic_id  = each.value.vnic_attachments[0].vnic_id
}
