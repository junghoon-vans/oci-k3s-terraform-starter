# OCI Terraform: ARM Always Free 4 Nodes

Run Terraform commands from `infra/terraform`.

This project creates 4 OCI ARM Always Free instances with modular Terraform:

- `bastion-1` in a public subnet (public IP assigned)
- `k3s-node-1`, `k3s-node-2`, `k3s-node-3` in a private subnet (no public IP)
- All 4 instances use identical compute spec:
  - Image: Canonical Ubuntu 24.04 build `2026.01.29-0` (set explicitly with `image_ocid`)
  - Shape: `VM.Standard.A1.Flex`
  - OCPU: `1`
  - Memory: `6 GB`
  - Boot Volume: `50 GB`

## Project Structure

```text
.
├── backend.tf.example
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
└── modules
    ├── compute
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── network
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── security
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

This layout is directly usable as a ZIP for OCI Resource Manager stack upload.

## What Gets Created

- VCN
- Public subnet + route table + Internet Gateway
- Private subnet + route table + NAT Gateway
- NSGs and NSG rules
  - Bastion NSG
    - Ingress `22/tcp` from `allowed_ssh_cidr`
    - Egress all
  - k3s NSG
    - Ingress `22/tcp` from Bastion NSG only
    - Ingress `6443/tcp` node-to-node
    - Ingress `8472/udp` node-to-node
    - Ingress `10250/tcp` node-to-node (optional, enabled by default)
    - Egress all

## k3s Role Plan and Cloud-init Placeholder

- `k3s-node-1`: server + worker (planned)
- `k3s-node-2`: worker (planned)
- `k3s-node-3`: worker (planned)

No real k3s bootstrap script is applied yet. This repository only prepares infra and role metadata for next-step cloud-init provisioning.

## Image Input

`image_ocid` is required and used directly for all instances.

Use an image OCID that matches:

- Canonical Ubuntu 24.04
- Build `2026.01.29-0`
- `VM.Standard.A1.Flex` compatibility

## Prerequisites

- Terraform `>= 1.5`
- OCI CLI/API key auth configured locally
- Proper IAM permissions in the target compartment

## Required Inputs

- `tenancy_ocid`
- `user_ocid`
- `fingerprint`
- `private_key_path`
- `region` (default `ap-seoul-1`)
- `compartment_ocid`
- `allowed_ssh_cidr`
- `ssh_authorized_keys`
- `image_ocid`
- optional `availability_domain`

Copy example vars:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then fill real values in `terraform.tfvars`.

## Remote tfstate (OCI Object Storage backend)

This repo provides `backend.tf.example` to avoid breaking OCI Resource Manager ZIP usage by default.

For local CLI backend enablement:

1. Copy and edit backend config

```bash
cp backend.tf.example backend.tf
```

2. Fill:
   - `bucket`
   - `namespace`
   - `region`
   - `key`

3. Initialize with migration:

```bash
terraform init -reconfigure
```

## Deploy

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Destroy

```bash
terraform destroy
```

## Outputs

- `bastion_public_ip`
- `bastion_private_ip`
- `k3s_private_ips`
- `instance_ocids`
- `vcn_id`
- `subnet_ids`

## SSH Access and ProxyJump Example

Access bastion directly:

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@<bastion_public_ip>
```

Access private k3s node through bastion with ProxyJump:

```bash
ssh -i ~/.ssh/id_ed25519 \
  -J ubuntu@<bastion_public_ip> \
  ubuntu@<k3s_node_private_ip>
```

Optional SSH config snippet:

```sshconfig
Host bastion
  HostName <bastion_public_ip>
  User ubuntu
  IdentityFile ~/.ssh/id_ed25519

Host k3s-node-1
  HostName <k3s_node_1_private_ip>
  User ubuntu
  IdentityFile ~/.ssh/id_ed25519
  ProxyJump bastion
```

## Capacity and Failure Troubleshooting

If apply fails on instance creation:

- Region/AD has temporary A1 capacity shortage
- Image build is not currently available in selected AD
- Always Free quota already consumed (A1 total limit: 4 OCPU, 24 GB memory)

Checks:

1. Retry with a different AD (`availability_domain`)
2. Verify `image_ocid` is valid in this region/AD
3. Confirm tenancy service limits and current usage
4. Confirm subnet CIDR and security rules are not overlapping/conflicting
