# Contributing

This is a template repo: nothing here is wired up to a live GitOps pipeline or
a real running cluster. If you clone/fork this to run your own cluster, the
guidance below describes the workflow this repo is built around -- adapt it
to however you actually deploy.

## Workflow

1. Branch off `main`. Use a short, descriptive branch name.
2. Change `.tf` / `.tftpl` files as needed.
3. Run locally before pushing:

   ```bash
   terraform fmt -recursive
   terraform validate
   ```

4. Open a PR. If you've configured the [CI/CD secrets](./README.md#cicd), the
   `plan` GitHub Actions job runs `fmt -check`, `validate`, and `plan`
   automatically, and posts the plan as a PR comment.
5. **Read the plan comment before merging** if your fork has `apply` wired up
   to run automatically on merge (see the README) -- that's the only review
   step before real infrastructure changes land.
6. Merge, then confirm the node(s) you changed reach `Ready` (see
   [Verification](./README.md#verification)).

## What a healthy plan looks like

For a small change (e.g. resizing a boot volume, tweaking a security rule),
expect a small, targeted diff -- a handful of resources added/changed, ideally
zero destroyed. Treat any of these as a stop-and-investigate signal, not
something to merge through:

- A plan that wants to **recreate resources that already exist** (e.g. the
  whole VCN, existing instances). This almost always means Terraform can't
  see the real remote state -- check that `terraform init` actually bound to
  the `oci` backend (a `Warning: Missing backend configuration` line in the
  init log means it silently fell back to local state, usually because no
  `backend "oci" {}` block exists in the committed config).
- Any unexpected `destroy` of `module.compute.oci_core_instance.this[...]`,
  the VCN, or the NLB.
- A plan far larger than your actual diff would suggest.

## Always Free budget

The default sizing in this template sits exactly at the Always Free ceiling
for a single tenancy -- there's no slack, so scaling up needs an explicit
tradeoff:

- **Block storage**: 4 nodes x 50 GB boot volume = 200 GB, all of the 200 GB
  Always Free allowance. Any PVC backed by an OCI Block Volume storage class
  (default minimum 50 GB) is billed. Prefer node-local storage (e.g. the
  `local-path` CSI provisioner) for anything that doesn't need to survive a
  node replacement.
- **ARM compute**: 2 x `A1.Flex` (1 OCPU / 6 GB each) = the full 2 OCPU / 12 GB
  Always Free ARM pool. A third ARM instance, or resizing an existing one
  larger, is billed.
- **AMD compute**: 2 x `E2.1.Micro` = the full Always Free AMD micro instance
  limit (2 instances). A third is billed.

## Secrets

If you wire up the CI workflow, don't add `terraform.tfvars` or `backend.hcl`
to git -- set values as repository secrets (see the table in
[README.md](./README.md#cicd)) or keep your own local, gitignored copies.

## Commit style

Conventional Commits (`feat(scope): ...`, `fix(scope): ...`, `chore(scope): ...`,
`ci(scope): ...`).
