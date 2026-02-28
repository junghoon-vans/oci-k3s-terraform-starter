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
    private_ip       = each.value.private_ip
    nsg_ids          = each.value.nsg_ids
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
    k3s_role            = each.value.role
    user_data           = each.value.user_data_base64
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
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
