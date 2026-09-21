# Lesson 14 — Cheatsheet, Comparison & FAQ

## 🎯 Goal

A single page to **bookmark**: every command, every block, Terraform vs
Terragrunt, migration steps, and troubleshooting for the errors you'll hit.

---

## 1. Command cheatsheet

```bash
# ── Everyday (run inside a unit folder) ──────────────────────────────
terragrunt init                          # download module + providers
terragrunt plan                          # preview changes
terragrunt apply                         # deploy (prompts for yes)
terragrunt apply -auto-approve           # deploy without prompt (CI)
terragrunt destroy                       # tear down (prompts)
terragrunt output                        # show outputs (like terraform output)
terragrunt validate                      # validate the rendered config
terragrunt fmt / terragrunt hclfmt       # format .tf / .hcl files

# ── Orchestration (run from any parent folder) ───────────────────────
terragrunt run-all plan                  # plan every unit below cwd
terragrunt run-all apply                 # apply all, in dependency order
terragrunt run-all destroy               # destroy all, REVERSE order ⚠️
terragrunt run-all apply --terragrunt-parallelism 4
terragrunt run-all apply --terragrunt-include-dir "*/app" --terragrunt-strict-include
terragrunt graph-dependencies            # print the dependency graph (dot format)

# ── Debugging ────────────────────────────────────────────────────────
terragrunt plan --terragrunt-log-level debug     # see the terraform cmd + cache paths
terragrunt render-json                           # show rendered config as JSON
terragrunt terragrunt-info                       # show working dirs/paths
ls .terragrunt-cache/                            # inspect downloaded module + generated files
```

## 2. Block cheatsheet (every `terragrunt.hcl` building block)

```hcl
# Which module + which Terraform version/args
terraform {
  source          = "../../../modules/vpc"   # local path | git::...//mod?ref=v1.0.0
  extra_arguments { ... }                    # (usually top-level extra_arguments instead)
}

# Inherit a parent config (backend, generate, inputs, hooks...)
include "root" {
  path           = find_in_parent_folders()  # refactor-proof parent lookup
  expose         = true                      # read parent locals via local.root.*
  merge_strategy = "shallow"                 # or "deep" for nested-map merging
}

# Backend, defined once at root (L03)
remote_state {
  backend = "s3"
  generate { path = "backend.tf"  if_exists = "overwrite_terragrunt" }
  config = {
    bucket = "..."
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "..."
  }
}

# Values: computed here (L04) / passed to Terraform (L04)
locals { env = basename(get_parent_terragrunt_dir()) }
inputs = { instance_type = "t3.micro"  tags = { Env = local.env } }

# Read outputs of another unit (L06) — implies ordering
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = { vpc_id = "vpc-mock" }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}
# Ordering only, no outputs (L06)
dependencies { paths = ["../vpc", "../db"] }

# Generate files (provider/versions) before Terraform runs (L07)
generate "provider" {
  path = "provider.tf"  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" { region = "us-east-1" }
EOF
}

# Hooks around Terraform commands (L08)
before_hook "lint" { commands = ["apply", "plan"]  execute = ["tflint"] }
after_hook  "done" { commands = ["apply"]          execute = ["echo", "done!"] }
error_hook  "oops" { commands = ["apply", "plan"]  execute = ["echo", "failed!"] }

# Extra CLI flags / env for Terraform (L08)
extra_arguments "vars" {
  commands  = ["apply", "plan"]
  arguments = ["-lock-timeout=20m"]
}

# Auto-retry flaky errors (L08)
retryable_errors = ["(?s).*Throttling.*"]
```

## 3. Terraform vs Terragrunt — head to head

| Concern | Plain Terraform | + Terragrunt |
|---|---|---|
| Backend per module | hand-written `backend.tf` × N | `remote_state` once at root |
| Multi-env reuse | copy-paste folders | `source` + `inputs` wrappers |
| Cross-module values | manual copy / `terraform_remote_state` | `dependency` + `mock_outputs` |
| Multi-module deploys | manual ordering × N commands | `run-all` in dependency order |
| Provider pinning | per-module blocks | root `generate` (one version) |
| Pre/post steps | shell scripts around TF | `before/after/error_hook` |
| Flaky API errors | re-run by hand | `retryable_errors` auto-retry |

## 4. Migrating existing Terraform to Terragrunt (5 steps)

```
1. EXTRACT modules: move reusable .tf into modules/<name>/,
   delete backend/provider blocks, parametrize with variables.
2. ADD root terragrunt.hcl: remote_state + provider generate + retries.
3. ADD live/ wrappers: one folder per old stack, with source + inputs
   matching the old .tfvars.
4. IMPORT state: point key at the OLD state path temporarily
   (`key = "old/path/terraform.tfstate"`), run `terragrunt init -migrate-state`,
   then switch to the standard key scheme. For many states, script it.
5. VERIFY: `run-all plan` should show ZERO changes (same infra, new wrapper).
   Commit, celebrate, then delete the old backend.tf files.
```

## 5. FAQ / Troubleshooting

**`terraform: command not found` when running terragrunt?**
→ Terraform isn't on PATH. Install it (L01); Terragrunt shells out to it.

**"Output X not found" in a dependency?**
→ The upstream module lacks `output "X"`. Add it, apply upstream, retry.

**`plan` works but `apply` says mock outputs / missing state?**
→ You applied downstream before upstream. Apply upstream first (or `run-all`).

**Two units fighting over one state file?**
→ Duplicate backend `key`. Use `${path_relative_to_include()}` (L03), one folder
per unit, and never hand-type keys.

**`run-all` order looks wrong?**
→ Ordering comes ONLY from `dependency`/`dependencies`. Missing edge = missing
wait. Check with `graph-dependencies`.

**"Cycle detected" error?**
→ A depends on B depends on A. Break the cycle (usually one direction should be
a data lookup or a merged unit, not a dependency).

**State lock stuck (`Error acquiring the state lock`)?**
→ Someone's apply died mid-run. Verify NOBODY is applying, then
`terragrunt force-unlock <LOCK-ID>` (and reduce lock contention with retries, L08).

**How do I use a different Terraform binary (tofu / tfenv)?**
→ `terragrunt --tf-path tofu plan`, or set `terraform_binary = "tofu"` in config.

**Terragrunt version vs Terraform version conflicts?**
→ Check the official compatibility matrix; pin both versions in CI
(`terraform_version_constraint` exists too).

## 6. Where to go from here

- [Lesson 15 — CI/CD Pipelines](../15-cicd-pipelines/README.md) ⭐ Level-3: plan on PR,
  gated prod applies, OIDC auth, drift detection (with copy-paste workflows)
- Official docs: **terragrunt.gruntwork.io** (function + CLI reference)
- Gruntwork blog: production patterns (multi-account landing zones, CIS baselines)
- Practice: extend the [capstone](../13-capstone-project/README.md) (RDS, ALB,
  second region, CI pipeline), then split `infra-live` / `infra-modules` repos.

---

## 🎓 Course recap — the whole mental model in 30 seconds

```
modules/  = HOW (generic Terraform, versioned)        → Lessons 02, 10
live/     = WHAT + WHERE + VALUES (thin wrappers)     → Lessons 04, 05, 09
root      = POLICY ONCE (backend/provider/retries)    → Lessons 03, 07, 08
wiring    = dependency + run-all (order + outputs)    → Lessons 06, 11
power     = functions (env/config/AWS/paths)          → Lesson 12
```

**Terragrunt is a thin wrapper for Terraform: it prepares (download, generate,
render, order) and then calls real Terraform.** Everything else is a consequence
of that sentence. Go build something! 🚀
