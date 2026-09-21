# Terraform

Hands-on Terraform + Terragrunt learning repository.

## 📖 Start here: Terragrunt Tutorial (basic → advanced)

👉 **[terragrunt-tutorial/](terragrunt-tutorial/)** — a 17-lesson course
(Lesson 00–16) that explains every Terragrunt concept with runnable examples:

- What Terragrunt is & why it's a "Terraform wrapper"
- `terragrunt.hcl`, `terraform { source }`, `inputs`, `locals`
- `remote_state`, `include` / DRY hierarchy, `dependency` + mocks
- `generate`, hooks, `extra_arguments`, retries
- Multi-env (`dev/stage/prod`) × multi-region layouts
- Reusable module catalogs, `run-all` orchestration, built-in functions
- Capstone: full AWS project (VPC + EC2 + S3) + cheatsheet & FAQ
- ⭐ Level-3: CI/CD pipelines (plan on PR, gated prod, OIDC, drift detection)
- 🏢 Real company challenges: problems → solutions, incident runbooks, interview prep

Lessons 00–12 & 14 use free local providers (zero cloud cost); Lessons 10 & 13
include real AWS examples (marked ⚠️, destroy after use).

## Other folders (plain Terraform basics)

| Folder | Contents |
|---|---|
| [`instance/`](instance) | First EC2 instance + provider + variables |
| [`variables/`](variables) | Variable types: string/number/bool/list/map/object + validation |
| [`Nginx/`](Nginx) | EC2 + Nginx provisioning example |

## 🧪 POCs (point-in-time fixes, with proof)

| Folder | Contents |
|---|---|
| [`poc-deprecated-attr/`](poc-deprecated-attr) | Reproduce + fix `data.aws_region.current.name` v6 deprecation, occurrence counter, Renovate setup |
