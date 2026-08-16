# oci-k3s-terraform-template

Terraform starter for a k3s cluster on the OCI Always Free tier: 2 ARM
(`A1.Flex`) nodes plus 2 AMD (`E2.1.Micro`) nodes, with Tailscale bootstrap.
This is a template -- clone it, point it at your own OCI tenancy, and adapt
it as needed. See [CONTRIBUTING.md](./CONTRIBUTING.md) for the PR/plan
workflow this repo uses.

## Topology

- `k3s-node-1`: k3s server + agent (ARM, `A1.Flex`)
- `k3s-node-2`: k3s agent (ARM, `A1.Flex`)
- `k3s-amd-1`, `k3s-amd-2`: k3s agents (AMD, `E2.1.Micro`), labeled
  `workload=amd64-tiny` and tainted `workload=amd64-tiny:NoSchedule` so only
  workloads that explicitly tolerate/target them get scheduled there

All nodes are private-only and accessed through Tailscale.
A public OCI Network Load Balancer (NLB) is provisioned for ingress (80/443) and forwards to node ports (30080/30443) on the two ARM nodes only.

## What gets created

- 4 k3s instances in private subnet (`10.0.10.0/24`): 2 ARM (`A1.Flex`) + 2 AMD (`E2.1.Micro`)
- VCN, public/private subnets, route tables, IGW, NAT Gateway
- Public OCI NLB for ingress on 80/443
- NSG rules for node-to-node k3s traffic and NLB-to-node ingress
- Cloud-init bootstrap for k3s and Tailscale tags

Always Free sizing (this fully consumes the block storage allowance -- see
[CONTRIBUTING.md](./CONTRIBUTING.md#always-free-budget) before adding more
nodes or larger disks):

- ARM: `VM.Standard.A1.Flex`, `1 OCPU` / `6 GB` RAM / `50 GB` boot volume each -- 2 nodes = 2 of the 2 OCPU / 12 GB Always Free ARM compute pool
- AMD: `VM.Standard.E2.1.Micro`, `50 GB` boot volume each -- 2 nodes = 2 of the 2 Always Free AMD micro instance limit
- Boot volumes: 4 nodes x 50 GB = 200 GB, all of the 200 GB Always Free block storage allowance. Any PVC backed by an OCI Block Volume storage class is billed beyond this; prefer node-local storage (e.g. `local-path`) for anything that doesn't need to survive a node replacement.

## Project structure

```text
.
├── backend.tf
├── backend.hcl.example
├── CONTRIBUTING.md
├── main.tf
├── nlb.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
├── .github/
│   └── workflows/
│       └── terraform.yml
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
- `image_ocid` (ARM image), `amd_image_ocid` (AMD image), `k3s_token`
- `tailscale_auth_key_server`, `tailscale_auth_key_agent`

Optional:

- `availability_domain`
- `public_subnet_cidr`
- `k3s_version`
- `k3s_disable_traefik`
- `k3s_server_enable_agent` (default `true`)
- `amd_boot_volume_size_in_gbs` (default `50`)
- `ingress_listener_http_port` (default `80`)
- `ingress_listener_https_port` (default `443`)
- `ingress_nodeport_http` (default `30080`)
- `ingress_nodeport_https` (default `30443`)

## Quick start

1. Prepare local config files. `backend.tf` only declares an empty `backend "oci" {}`
   block and is committed -- real bucket/namespace/region values are supplied
   separately (as a local `backend.hcl` here, or as `-backend-config` flags in CI)
   so they never need to live in a tracked file.

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

2. Run Terraform.

```bash
terraform init -reconfigure -backend-config=backend.hcl
terraform plan -out tfplan
terraform apply tfplan
```

## CI/CD

`.github/workflows/terraform.yml` is a reference GitHub Actions pipeline --
it won't run successfully until you configure the secrets below for your own
OCI tenancy:

- Pull requests touching `**.tf` / `**.tftpl`: `terraform fmt -check`, `validate`, and
  `plan`, with the plan posted as a PR comment.
- Push to `main` (i.e. merging a PR): `terraform plan` followed immediately by
  `terraform apply -auto-approve`, fully automatic. There is no manual approval gate --
  GitHub's "required reviewers" environment protection needs a paid plan for private
  repos, so review happens at the PR stage (read the plan comment before merging).
  Read a healthy-vs-unhealthy plan checklist in [CONTRIBUTING.md](./CONTRIBUTING.md#what-a-healthy-plan-looks-like)
  before merging anything.
- `workflow_dispatch` is also available for an ad-hoc plan+apply run outside of a merge.

Required repository secrets (no `terraform.tfvars` or `backend.hcl` are committed, so
CI sources every value from secrets):

| Secret | Maps to |
| --- | --- |
| `OCI_TENANCY_OCID` | `tenancy_ocid` |
| `OCI_USER_OCID` | `user_ocid` |
| `OCI_FINGERPRINT` | `fingerprint` |
| `OCI_PRIVATE_KEY` | contents of the API signing key PEM (written to a temp file as `private_key_path`) |
| `OCI_REGION` | `region` |
| `OCI_COMPARTMENT_OCID` | `compartment_ocid` |
| `OCI_SSH_AUTHORIZED_KEYS` | `ssh_authorized_keys` |
| `OCI_ARM_IMAGE_OCID` | `image_ocid` |
| `OCI_AMD_IMAGE_OCID` | `amd_image_ocid` |
| `K3S_TOKEN` | `k3s_token` |
| `TAILSCALE_AUTH_KEY_SERVER` | `tailscale_auth_key_server` |
| `TAILSCALE_AUTH_KEY_AGENT` | `tailscale_auth_key_agent` |
| `TF_STATE_BUCKET` | backend `bucket` |
| `TF_STATE_NAMESPACE` | backend `namespace` |

Set secrets with `gh secret set NAME --repo <owner>/<repo> < file` (for the PEM
key) or `gh secret set NAME --repo <owner>/<repo> --body "value"`.

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

Expected: `k3s-node-1`, `k3s-node-2`, `k3s-amd-1`, and `k3s-amd-2` are all `Ready`.

If SSH is denied, update Tailscale ACL/tag ownership so your operator identity can reach `tag:k3s-server` and `tag:k3s-agent`.

## Notes

- `metadata.user_data` changes are ignored on existing instances (see
  `modules/compute`'s `lifecycle.ignore_changes`) so cloud-init/template edits
  don't force instance replacement. Recreate the instance explicitly (taint it,
  or change something else that forces replacement) if you need a node to pick
  up new cloud-init content.
- Before removing any node, verify no `local-path` PVs and no workload-specific
  node labels/taints remain bound to it, and drain it first (daemonsets ignored,
  emptyDir deletion allowed).
- Keep `terraform.tfvars`, `backend.hcl`, keys, and kubeconfig out of git. `backend.tf`
  itself is committed but only declares an empty `backend "oci" {}` block -- it holds
  no real values.
