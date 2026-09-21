# Lesson 07 — Generate Blocks (dynamic provider/backend files)

## 🎯 Goal

Use `generate` to auto-create `provider.tf` (and other files) per environment —
so modules stay provider-free and regions/versions change in one place.

---

## 1. Why generate files?

A reusable module should NOT hardcode its provider:

```hcl
# ❌ Inside modules/vpc/main.tf — now the module only works in us-east-1?!
provider "aws" {
  region = "us-east-1"
}
```

But Terraform *requires* a provider configuration from somewhere. Options:

| Approach | Downside |
|---|---|
| Provider block in every module | Copy-paste, region locked per copy |
| Provider block per environment folder | Another file per env to maintain |
| ✅ `generate` in Terragrunt | Written once at root, rendered per unit with correct values |

## 2. The `generate` block

```hcl
# live/terragrunt.hcl (root) — generates provider.tf for EVERY unit
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}
```

| Argument | Meaning |
|---|---|
| `path` | Filename to write inside the working dir (`provider.tf`, `backend.tf`, `versions.tf`…) |
| `if_exists` | `overwrite` (always), `overwrite_terragrunt` (only overwrite files Terragrunt created — safe default ✅), `skip` (keep existing), `error` (fail if present) |
| `contents` | File body — full HCL interpolation allowed (`${local.x}`, conditionals, functions) |

The file is written into the **cache dir** before Terraform runs, so Terraform
sees a normal `provider.tf`. Your repo stays clean — generated files are never
committed (note `*_generated.tf` / `provider.tf` in `.gitignore`).

> You already met `generate` once: `remote_state { generate { path = "backend.tf" } }`
> in Lesson 03 is the same idea, specialized for backends.

## 3. Real-world root provider pattern

```hcl
# live/terragrunt.hcl
locals {
  # Region derived from folder: live/prod/us-east-1/... → "us-east-1"
  aws_region = basename(get_parent_terragrunt_dir())
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      ManagedBy = "terragrunt"
    }
  }
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}
```

One root config now enforces the **same provider version + region wiring +
default tags** across every unit. Upgrading the AWS provider = one line, one PR.

## 4. This lesson's example (runnable, no cloud)

We generate a `versions.tf` + a `provider.tf` (local provider) for a trivial
module, proving the module file itself contains neither:

```
07-generate/
├── live/dev/demo/terragrunt.hcl  # generate blocks + source + inputs
└── modules/demo/main.tf          # NO provider, NO versions block!
```

```bash
cd live/dev/demo
terragrunt init    # generates provider.tf + versions.tf in cache, then inits
terragrunt apply   # works — provider came from the generated file
terragrunt destroy
```

🔍 **Inspect the magic:** after `init`, open
`.terragrunt-cache/<hash>/*/provider.tf` — that's the file Terragrunt wrote.

## 5. When NOT to generate

- Module-specific provider *aliases* (`provider = aws.alternate`) still live in
  the module — `generate` is for the shared/default config.
- Don't generate `variables.tf`/`outputs.tf` — those define the module's
  contract and belong in the module.
- Keep generated content small and boring (providers, versions, backend).
  Business logic goes in modules.

---

## ✏️ Exercises

1. After `init` in the example, find and read the generated `provider.tf` and
   `versions.tf` inside `.terragrunt-cache/`.
2. Change `if_exists` to `"skip"`, create your own `provider.tf` in the cache
   dir, re-run `init`, and observe that yours survives. Then revert.
3. Write a `generate "backend"` experiment? Don't — use `remote_state` instead
   (Lesson 03). Explain why to yourself in one sentence.
   (Answer: `remote_state` also runs `init -backend-config` correctly and keeps
   backend settings DRY + dynamic; raw `generate` of backend.tf is the manual path.)

## ✅ Key takeaways

- `generate` writes files (provider/versions) into the working dir before Terraform runs.
- Root-level `generate` = one provider/version/tags policy for all units.
- Modules stay provider-free and reusable across regions/accounts.

Next 👉 [Lesson 08 — Hooks](../08-hooks/README.md)
