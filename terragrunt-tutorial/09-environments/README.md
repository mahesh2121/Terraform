# Lesson 09 — Multi-Environment Layout (dev/stage/prod × regions)

## 🎯 Goal

Design the `live/` tree professionals use: environments × regions × units, with
per-env values flowing through `env.hcl` files — and a safe promotion flow.

---

## 1. The standard layout

```
live/
├── terragrunt.hcl                    # ROOT: backend, provider gen, retries...
├── dev/
│   ├── env.hcl                       # dev-wide: account, sizes, feature flags
│   ├── us-east-1/
│   │   ├── region.hcl                # region-wide: AZs, region name
│   │   ├── vpc/terragrunt.hcl
│   │   └── app/terragrunt.hcl
│   └── eu-west-1/
│       ├── region.hcl
│       ├── vpc/terragrunt.hcl
│       └── app/terragrunt.hcl
├── stage/ ...                        # same shape, different values
└── prod/ ...                         # same shape, different values
```

Why this shape?
- **One folder = one state file** (Lesson 03's key guarantees isolation).
- Adding a region = copy a folder, edit `region.hcl`. Adding an env = copy env
  folder, edit `env.hcl`. Modules (`source`) don't change at all.
- `run-all` can target any subtree: whole prod, one region, one unit.

## 2. `env.hcl` / `region.hcl` — the value layers

These are plain Terragrunt configs holding **only `locals`** (never units —
that's why they don't use the name `terragrunt.hcl`):

```hcl
# live/dev/env.hcl
locals {
  env               = "dev"
  account_id        = "111111111111"
  instance_type     = "t3.micro"
  replicas          = 1
  enable_monitoring = false
}
```

```hcl
# live/dev/us-east-1/region.hcl
locals {
  aws_region = "us-east-1"
  azs        = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

Units read them and merge (pattern from Lessons 05 + 12):

```hcl
# live/dev/us-east-1/app/terragrunt.hcl
locals {
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

inputs = {
  instance_type = local.env.locals.instance_type  # dev → t3.micro
  aws_region    = local.region.locals.aws_region  # us-east-1
  ...
}
```

## 3. Promotion flow: dev → stage → prod

Because only **values** differ (same modules, same structure), promotion is boring
— and boring is good:

```
1. Change module version or inputs in  live/dev/.../terragrunt.hcl
2. terragrunt plan + apply in dev, verify ✅
3. Copy the SAME change to live/stage/...  (or open one PR touching both)
4. Verify in stage ✅
5. Repeat for prod ✅ (often with manual approval in CI)
```

Tips:
- Pin module versions per env (`?ref=v1.2.0` in dev, `?ref=v1.1.0` in prod) so
  prod upgrades deliberately, not accidentally.
- CI should `run-all plan` on PRs and `run-all apply` on merge — per env folder.

## 4. Account/region isolation checklist

- [ ] Separate AWS accounts per env (dev/stage/prod) — blast-radius isolation.
- [ ] Separate state buckets per account+region (Lesson 03 pattern).
- [ ] `allowed_account_ids` guard in generated provider so dev config can never
      run against prod:

```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${local.region}"
  allowed_account_ids = ["${local.account_id}"]  # 🛡️ wrong account = instant error
}
EOF
}
```

## 5. This lesson's example (runnable, no cloud)

A miniature live tree with **two envs × one region**, sharing one root + module:

```
09-environments/
├── terragrunt.hcl                        # root (shared inputs)
├── live/dev/env.hcl + us-east-1/region.hcl + app/terragrunt.hcl
├── live/prod/env.hcl + us-east-1/region.hcl + app/terragrunt.hcl
└── modules/app/
```

```bash
cd live/dev/us-east-1/app && terragrunt apply   # small dev deployment
cd ../../../../prod/us-east-1/app && terragrunt apply  # bigger prod deployment
# Compare the two generated files — same module, different values.
```

---

## ✏️ Exercises

1. Add a `stage` env by copying `live/dev` → `live/stage`, editing `env.hcl`
   values. How many files did you touch? (Should be ~2.)
2. Add the `allowed_account_ids` guard to a generated provider (Lesson 07 style)
   in the root config.
3. Sketch (on paper) where you'd add `eu-west-1` under `prod`. Which files are
   new vs reused?

## ✅ Key takeaways

- Layout: `live/<env>/<region>/<unit>`; values in `env.hcl`/`region.hcl`.
- Same modules everywhere — only values differ → safe promotion dev→stage→prod.
- Isolate by account+region; guard with `allowed_account_ids`.

Next 👉 [Lesson 10 — Reusable Module Catalog](../10-modules-catalog/README.md)
