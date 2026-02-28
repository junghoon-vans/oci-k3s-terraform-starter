# oci-terraform monorepo

- `infra/terraform`: OCI infrastructure as code (network, security, compute).
- `platform/cloud-init`: cloud-init templates for bastion and k3s bootstrap.

## Quick start

```bash
cd infra/terraform
terraform init
terraform plan -out tfplan
```
