# oci-k3s-terraform-starter

Terraform starter for building a 2-node OCI ARM Always Free environment with k3s and Tailscale bootstrap.

## Topology

- `k3s-node-1`: k3s server + agent
- `k3s-node-2`: k3s agent

All nodes are private-only and accessed through Tailscale.
A public OCI Network Load Balancer (NLB) is provisioned for ingress (80/443) and forwards to node ports (30080/30443).

## What gets created

- 2 k3s instances in private subnet (`10.0.10.0/24`)
- VCN, public/private subnets, route tables, IGW, NAT Gateway
- Public OCI NLB for ingress on 80/443
- NSG rules for node-to-node k3s traffic and NLB-to-node ingress
- Cloud-init bootstrap for k3s and Tailscale tags

ARM Always Free sizing:

- Shape: `VM.Standard.A1.Flex`
- `1 OCPU`, `6 GB` RAM, `50 GB` boot volume
- 2 nodes use 100 GB of the 200 GB Always Free boot/block volume allowance, leaving room to grow the remaining nodes.

## Project structure

```text
.
├── backend.tf.example
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
├── cloud-init/
│   ├── k3s-server.yaml.tftpl
│   └── k3s-agent.yaml.tftpl
└── modules/
    ├── network/
    ├── security/
    └── compute/
```

## Required inputs

- `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`
- `compartment_ocid`, `ssh_authorized_keys`
- `image_ocid`, `k3s_token`
- `tailscale_auth_key_server`, `tailscale_auth_key_agent`

Optional:

- `availability_domain`
- `public_subnet_cidr`
- `k3s_version`
- `k3s_disable_traefik`
- `k3s_server_enable_agent` (default `true`)
- `ingress_listener_http_port` (default `80`)
- `ingress_listener_https_port` (default `443`)
- `ingress_nodeport_http` (default `30080`)
- `ingress_nodeport_https` (default `30443`)

## Quick start

1. Prepare local config files.

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
```

2. Run Terraform.

```bash
terraform init -reconfigure
terraform plan -out tfplan
terraform apply tfplan
```

## Outputs

- `k3s_private_ips`
- `instance_ocids`
- `vcn_id`
- `subnet_ids`
- `ingress_nlb`

## Verification

1. Check tailnet connectivity.

```bash
tailscale status
```

2. SSH to k3s server.

```bash
tailscale ssh ubuntu@k3s-node-1
```

3. Verify cluster health.

```bash
sudo k3s kubectl get nodes -o wide
```

Expected: `k3s-node-1/2` are `Ready`.

If SSH is denied, update Tailscale ACL/tag ownership so your operator identity can reach `tag:k3s-server` and `tag:k3s-agent`.

## Notes

- `metadata.user_data` changes can force instance replacement.
- Before applying node removal, drain `k3s-node-3` and `k3s-node-4` and verify no local-path PVs or workload-specific node labels remain on them.
- Keep `terraform.tfvars`, `backend.tf`, keys, and kubeconfig out of git.

## Node removal risk checklist

This configuration intentionally keeps only `k3s-node-1` and `k3s-node-2`.
Before applying this change to an existing 4-node cluster:

- Verify all local-path PVs are bound to `k3s-node-2`.
- Verify service-specific node labels only remain on `k3s-node-2`.
- Drain `k3s-node-3` and `k3s-node-4` with daemonsets ignored and emptyDir deletion allowed.
- Confirm Argo CD applications are `Synced`; `platform-core` may remain `Progressing` if a platform workload reports non-terminal health.
- Confirm the OCI NLB backend list after apply only contains `10.0.10.11` and `10.0.10.12` for ports `30080` and `30443`.

Expected Terraform impact:

- Destroy `module.compute.oci_core_instance.this["k3s-node-3"]`.
- Destroy `module.compute.oci_core_instance.this["k3s-node-4"]`.
- Remove NLB backend targets for `10.0.10.13` and `10.0.10.14`.
- Keep the VCN, subnets, NSGs, NLB, `k3s-node-1`, and `k3s-node-2`.
