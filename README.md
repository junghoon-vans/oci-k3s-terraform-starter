# oci-k3s-terraform-starter

Terraform starter for building a 4-node OCI ARM Always Free environment with k3s bootstrap.

## Why this repo

- Opinionated baseline for OCI networking + compute + security
- k3s bootstrap with cloud-init (1 server + 2 agents)
- Starter layout that is easy to extend for GitOps/Helm later

## What gets created

- 1 bastion instance in a public subnet (`bastion-1`)
- 3 k3s instances in a private subnet (`k3s-node-1/2/3`)
- VCN, subnets, route tables, Internet Gateway, NAT Gateway
- NSG-based access rules for SSH and k3s traffic

All nodes are configured for ARM Always Free sizing:

- Shape: `VM.Standard.A1.Flex`
- `1 OCPU`, `6 GB` RAM, `50 GB` boot volume

## Repository layout

- [`terraform/`](terraform): Terraform root stack and modules
- [`cloud-init/`](cloud-init): bastion/k3s bootstrap templates

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
- `compartment_ocid`, `allowed_ssh_cidr`, `ssh_authorized_keys`
- `image_ocid`, `k3s_token`

3. Initialize and deploy.

```bash
terraform init -reconfigure
terraform plan -out tfplan
terraform apply tfplan
```

## Post-Deploy Verification

From the k3s server node:

```bash
sudo k3s kubectl get nodes -o wide
```

Expected: `k3s-node-1`, `k3s-node-2`, `k3s-node-3` all `Ready`.
