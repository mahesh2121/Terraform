# Lesson 04 — Inputs & Locals

## 🎯 Goal

Master the two ways values flow through a wrapper: **`inputs`** (into
Terraform) and **`locals`** (computed values inside Terragrunt).

---

## 1. `inputs` — Terraform variables without `.tfvars` files

In plain Terraform you pass variables with `-var`, `-var-file`, or
`terraform.tfvars`. In Terragrunt you declare them in the wrapper:

```hcl
terraform {
  source = "../../../modules/ec2"
}

inputs = {
  instance_type = "t3.micro"          # → variable "instance_type"
  instance_name = "web-dev"           # → variable "instance_name"
  tags = {                            # complex types work fine
    Environment = "dev"
    Owner       = "team-a"
  }
}
```

Rules:
- Every key must match a `variable` in the module (extra keys → error, which is
  good: typos fail fast).
- Terragrunt renders `inputs` to an auto-generated `terraform.tfvars.json` in
  the cache dir — inspect it after `init` to demystify the magic.
- Precedence reminder: `inputs` behave like a tfvars file, so `-var` CLI flags
  still override them, and `TF_VAR_*` env vars lose to them. Order (low→high):
  defaults < `terraform.tfvars`/`inputs` < `*.auto.tfvars` < `-var`/`-var-file`.

That last point gives you a clean layering strategy:

```
module defaults  →  root inputs (org-wide)  →  env inputs  →  unit inputs
(lowest priority)                                              (highest)
```

You'll implement exactly this layering with `include` + `merge()` in Lesson 05.

## 2. `locals` — compute once, reuse everywhere in the file

`locals` are Terragrunt-side named values: string building, conditionals,
reading files, calling functions. They keep `inputs` and `remote_state` DRY
*within* one file:

```hcl
locals {
  # Convention: derive names from the folder layout — zero hardcoding.
  env         = basename(get_parent_terragrunt_dir())  # "dev"
  name_prefix = "myapp-${local.env}"                   # "myapp-dev"

  common_tags = {
    Environment = local.env
    ManagedBy   = "terragrunt"
  }

  # Conditionals: prod gets the big machine, everything else the small one.
  instance_type = local.env == "prod" ? "t3.medium" : "t3.micro"
}

inputs = {
  instance_name = "${local.name_prefix}-web"
  instance_type = local.instance_type
  tags          = local.common_tags
}
```

Key facts:
- Reference with `local.name` (singular `local`, like Terraform).
- Locals can use **any Terragrunt function** (`get_env`, `read_terragrunt_config`,
  path helpers…) — the full function tour is Lesson 12.
- Locals are file-scoped; to share across files, put them in a parent config
  and `expose` them (Lesson 05).

## 3. Putting it together (this lesson's example)

```
04-inputs-locals/
├── live/dev/server/terragrunt.hcl   # locals + inputs in action (local provider)
└── modules/server/                  # module with string/number/bool/map variables
```

The wrapper computes a name prefix and tags from `locals`, derives an instance
type with a conditional, and passes everything via `inputs`. Run it free:

```bash
cd live/dev/server
terragrunt apply   # writes server-dev.txt; no cloud needed
cat $(terragrunt output -raw file_path)
terragrunt destroy
```

## 4. Common patterns cheat-sheet

```hcl
locals {
  env = get_env("ENV", "dev")                        # env var with default
  azs = ["${local.region}a", "${local.region}b"]     # build lists
  merged_tags = merge(local.common_tags, {           # merge maps
    Service = "web"
  })
}

inputs = {
  create_monitoring = local.env == "prod"            # booleans from logic
  subnet_ids        = dependency.vpc.outputs.subnet_ids  # (Lesson 06)
}
```

> ⚠️ **Secrets don't belong in `inputs`.** State files store them in plaintext.
> Pass secrets via env vars, Vault/Secrets Manager data sources, or SOPS — never
> hardcode them in `terragrunt.hcl` (and never commit them, same as `.tf`).

---

## ✏️ Exercises

1. In the example, add a `locals` value `upper_env = upper(local.env)` and use
   it in the file content. Apply and verify.
2. Copy the wrapper to `live/prod/server/terragrunt.hcl` with different inputs.
   Predict the filename before you run `plan`.
3. Intentionally add a typo'd key to `inputs` (e.g. `massage`) and run `plan` —
   observe the fail-fast error, then remove it.

## ✅ Key takeaways

- `inputs` = module variables, rendered to tfvars automatically.
- `locals` = computed helper values (`local.name`), with functions + conditionals.
- Derive values from folder/env instead of hardcoding; never put secrets in inputs.

Next 👉 [Lesson 05 — Include & DRY Hierarchy](../05-include-dry/README.md)
