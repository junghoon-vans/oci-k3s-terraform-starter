# oci-k3s-terraform-starter

Terraform starter for building a 4-node OCI ARM Always Free environment with k3s and Tailscale bootstrap.

## Topology

- `k3s-node-1`: k3s server + agent
- `k3s-node-2`: k3s agent
- `k3s-node-3`: k3s agent
- `k3s-node-4`: k3s agent

All nodes are private-only and accessed through Tailscale.

## What gets created

- 4 k3s instances in private subnet (`10.0.10.0/24`)
- VCN, private route table, NAT Gateway
- NSG rules for node-to-node k3s traffic
- Cloud-init bootstrap for k3s and Tailscale tags

ARM Always Free sizing:

- Shape: `VM.Standard.A1.Flex`
- `1 OCPU`, `6 GB` RAM, `50 GB` boot volume

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
- `k3s_version`
- `k3s_disable_traefik`
- `k3s_server_enable_agent` (default `true`)

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

Expected: `k3s-node-1/2/3/4` are all `Ready`.

If SSH is denied, update Tailscale ACL/tag ownership so your operator identity can reach `tag:k3s-server` and `tag:k3s-agent`.

## Notes

- `metadata.user_data` changes can force instance replacement.
- Keep `terraform.tfvars`, `backend.tf`, keys, and kubeconfig out of git.
