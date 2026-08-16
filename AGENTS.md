# AGENTS.md

This repo is a Terraform **template**, not live infrastructure. Nobody's
cluster is on the other end of a `terraform apply` run from here -- there's
no real backend, no real secrets, no real OCI tenancy tied to this repo.
Keep that framing in mind: changes should stay generic and reusable, not
tailored to one person's cluster.

## Before changing anything

- Read [README.md](./README.md) for the current topology and required inputs.
- Read [CONTRIBUTING.md](./CONTRIBUTING.md) for the PR/plan workflow and the
  Always Free budget this template is sized against (there is no slack --
  4 nodes already use the full 200GB block storage allowance, full ARM OCPU
  pool, and full AMD micro-instance limit).

## The one gotcha worth knowing

`extra_config` (used to inject `node-label`/`node-taint` into an agent's
`k3s-agent.yaml.tftpl`) **must** use a plain `<<EOT ... EOT` heredoc with
literal, absolute indentation matching the surrounding YAML block (6 spaces
for keys, 8 for list items) -- not `<<-EOT`, which strips leading whitespace
and silently breaks the YAML nesting. If `extra_config`'s content lands at
less indentation than the `content: |` block it's supposed to live inside,
cloud-init treats it as top-level keys, schema validation fails, and
`write_files` entries after it can silently never get created. This exact
bug caused a multi-hour "why can't this node reach anything" debugging
session on the live cluster this template was extracted from. If you touch
`extra_config` or the cloud-init templates, verify by rendering locally
before pushing:

```bash
terraform init -backend=false
echo 'nonsensitive(base64decode(local.instance_definitions["k3s-amd-1"].user_data_base64))' | \
  TF_VAR_tenancy_ocid=x TF_VAR_user_ocid=x TF_VAR_fingerprint=x TF_VAR_private_key_path=/dev/null \
  TF_VAR_compartment_ocid=x TF_VAR_ssh_authorized_keys=x TF_VAR_amd_image_ocid=x TF_VAR_k3s_token=x \
  TF_VAR_tailscale_auth_key_server=x TF_VAR_tailscale_auth_key_agent=x TF_VAR_image_ocid=x \
  terraform console
```

Confirm `node-label`/`node-taint` (or whatever you added) appear nested
inside `content: |` at the same indentation as `server:`/`token:`/`node-ip:`,
not as a separate top-level block.

## Validating changes

```bash
terraform fmt -check -recursive
terraform validate
actionlint .github/workflows/terraform.yml   # if you touch the workflow
```

`terraform validate` doesn't need real credentials -- `terraform init
-backend=false` is enough for both `validate` and the console render above.

## Conventions

- Per-instance fields (`shape`, `image_ocid`, `ocpus`, `memory_in_gbs`,
  `boot_volume_size_in_gbs`) live on each entry in `local.instance_definitions`
  (`main.tf`), not as shared module-level variables -- this is what lets ARM
  and AMD nodes coexist under one `for_each` in `modules/compute`.
- `modules/compute`'s `oci_core_instance.this` ignores changes to `metadata`
  (see `lifecycle.ignore_changes`), so cloud-init/template edits don't force
  instance replacement by themselves. If you need a node to pick up new
  cloud-init content, taint it explicitly or change something else that
  forces replacement.
- Conventional Commits (`feat(scope): ...`, `fix(scope): ...`,
  `chore(scope): ...`, `ci(scope): ...`).
- No AI attribution in commit messages or PR bodies.
