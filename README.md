# oci-k3s-terraform-starter

Terraform starter for building a 4-node OCI ARM Always Free environment with k3s and Tailscale bootstrap.

## Why this repo

- Opinionated baseline for OCI networking + compute + security
- k3s bootstrap with cloud-init (1 server + 3 agents)
- Starter layout that is easy to extend for GitOps/Helm later

## What gets created

- 4 k3s instances in a private subnet (`k3s-node-1/2/3/4`)
- VCN, private subnet, route table, NAT Gateway
- NSG-based access rules for k3s node communication
- Tailscale bootstrap for private access without bastion

All nodes are configured for ARM Always Free sizing:

- Shape: `VM.Standard.A1.Flex`
- `1 OCPU`, `6 GB` RAM, `50 GB` boot volume

## Repository layout

- [`terraform/`](terraform): Terraform root stack and modules
- [`cloud-init/`](cloud-init): k3s + tailscale bootstrap templates

## Prerequisites

- Terraform `>= 1.5`
- OCI CLI configured with API key auth (`~/.oci/config`)
- OCI IAM permissions for VCN, NSG, Compute, and Object Storage backend

## Quick Start

1. Prepare variables and backend config.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
```

2. Fill required values in `terraform.tfvars`:

- `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`
- `compartment_ocid`, `ssh_authorized_keys`
- `image_ocid`, `k3s_token`, `tailscale_auth_key_server`, `tailscale_auth_key_agent`

3. Initialize and deploy.

```bash
terraform init -reconfigure
terraform plan -out tfplan
terraform apply tfplan
```

## Post-Deploy Verification

1. Verify node connectivity from your laptop with Tailscale.

```bash
tailscale status
```

2. SSH to the k3s server over Tailscale (pick the server node name from `tailscale status`).

```bash
tailscale ssh ubuntu@<k3s-node-1-tailscale-name>
```

3. On the server, verify cluster state.

```bash
sudo k3s kubectl get nodes -o wide
```

Expected: `k3s-node-1`, `k3s-node-2`, `k3s-node-3`, `k3s-node-4` all `Ready`.

If Tailscale SSH is denied, confirm your ACL policy allows your user/group to access `tag:k3s-server` and `tag:k3s-agent`.
