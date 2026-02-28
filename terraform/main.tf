provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  selected_availability_domain = coalesce(var.availability_domain, data.oci_identity_availability_domains.ads.availability_domains[0].name)
  cloud_init_dir               = "${path.root}/../cloud-init"

  instance_definitions = {
    "k3s-node-1" = {
      subnet_id        = module.network.private_subnet_id
      assign_public_ip = false
      private_ip       = "10.0.10.11"
      nsg_ids          = [module.security.k3s_nsg_id]
      role             = "server+worker"
      user_data_base64 = base64encode(templatefile("${local.cloud_init_dir}/k3s-server.yaml.tftpl", {
        k3s_token           = var.k3s_token
        k3s_version         = var.k3s_version
        server_node_ip      = "10.0.10.11"
        disable_traefik     = var.k3s_disable_traefik
        server_enable_agent = var.k3s_server_enable_agent
        tailscale_auth_key  = var.tailscale_auth_key_server
        tailscale_tag       = "tag:k3s-server"
      }))
    }
    "k3s-node-2" = {
      subnet_id        = module.network.private_subnet_id
      assign_public_ip = false
      private_ip       = "10.0.10.12"
      nsg_ids          = [module.security.k3s_nsg_id]
      role             = "worker"
      user_data_base64 = base64encode(templatefile("${local.cloud_init_dir}/k3s-agent.yaml.tftpl", {
        k3s_token          = var.k3s_token
        k3s_version        = var.k3s_version
        server_node_ip     = "10.0.10.11"
        agent_node_ip      = "10.0.10.12"
        tailscale_auth_key = var.tailscale_auth_key_agent
        tailscale_tag      = "tag:k3s-agent"
      }))
    }
    "k3s-node-3" = {
      subnet_id        = module.network.private_subnet_id
      assign_public_ip = false
      private_ip       = "10.0.10.13"
      nsg_ids          = [module.security.k3s_nsg_id]
      role             = "worker"
      user_data_base64 = base64encode(templatefile("${local.cloud_init_dir}/k3s-agent.yaml.tftpl", {
        k3s_token          = var.k3s_token
        k3s_version        = var.k3s_version
        server_node_ip     = "10.0.10.11"
        agent_node_ip      = "10.0.10.13"
        tailscale_auth_key = var.tailscale_auth_key_agent
        tailscale_tag      = "tag:k3s-agent"
      }))
    }
    "k3s-node-4" = {
      subnet_id        = module.network.private_subnet_id
      assign_public_ip = false
      private_ip       = "10.0.10.14"
      nsg_ids          = [module.security.k3s_nsg_id]
      role             = "worker"
      user_data_base64 = base64encode(templatefile("${local.cloud_init_dir}/k3s-agent.yaml.tftpl", {
        k3s_token          = var.k3s_token
        k3s_version        = var.k3s_version
        server_node_ip     = "10.0.10.11"
        agent_node_ip      = "10.0.10.14"
        tailscale_auth_key = var.tailscale_auth_key_agent
        tailscale_tag      = "tag:k3s-agent"
      }))
    }
  }
}

module "network" {
  source = "./modules/network"

  compartment_ocid = var.compartment_ocid
  vcn_cidr_block   = var.vcn_cidr_block
  private_subnet   = var.private_subnet_cidr
}

module "security" {
  source = "./modules/security"

  compartment_ocid    = var.compartment_ocid
  vcn_id              = module.network.vcn_id
  enable_kubelet_port = var.enable_kubelet_port
}

module "compute" {
  source = "./modules/compute"

  compartment_ocid        = var.compartment_ocid
  availability_domain     = local.selected_availability_domain
  ssh_authorized_keys     = var.ssh_authorized_keys
  image_ocid              = var.image_ocid
  shape                   = var.shape
  ocpus                   = var.ocpus
  memory_in_gbs           = var.memory_in_gbs
  boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  instances               = local.instance_definitions
}
