# OCI Terraform: k3s + Tailscale (4 nodes)

Run Terraform commands from `terraform/`.

## Topology

- `k3s-node-1`: k3s server + agent
- `k3s-node-2`: k3s agent
- `k3s-node-3`: k3s agent
- `k3s-node-4`: k3s agent

All nodes are in private subnet and use Tailscale for access.

## Spec

- Image: Canonical Ubuntu 24.04 (`image_ocid` required)
- Shape: `VM.Standard.A1.Flex`
- OCPU: `1`
- Memory: `6 GB`
- Boot volume: `50 GB`

## Project Structure

```text
terraform/
├── backend.tf.example
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
└── modules/
    ├── network/
    ├── security/
    └── compute/
```

## Required Inputs

- `tenancy_ocid`
- `user_ocid`
- `fingerprint`
- `private_key_path`
- `region` (default `ap-seoul-1`)
- `compartment_ocid`
- `ssh_authorized_keys`
- `image_ocid`
- `k3s_token`
- `tailscale_auth_key_server`
- `tailscale_auth_key_agent`

Optional:

- `availability_domain`
- `k3s_version`
- `k3s_disable_traefik`
- `k3s_server_enable_agent` (default `true`)

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
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

1. Confirm nodes are online in your tailnet:

```bash
tailscale status
```

2. SSH to `k3s-node-1` via Tailscale:

```bash
tailscale ssh ubuntu@<k3s-node-1-tailscale-name>
```

3. On `k3s-node-1`, check cluster health:

```bash
sudo k3s kubectl get nodes -o wide
```

Expected: `k3s-node-1/2/3/4` all `Ready`.

If access is blocked, update Tailscale ACL/tag ownership so your operator identity can reach `tag:k3s-server` and `tag:k3s-agent`.

## Notes

- `metadata.user_data` changes can force instance replacement.
- Keep `terraform.tfvars`, `backend.tf`, keys, and kubeconfig out of git.
