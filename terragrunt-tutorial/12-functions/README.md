# Lesson 12 — Built-in Functions (the power tools)

## 🎯 Goal

Know the function library that makes wrappers dynamic: reading other configs,
environment variables, AWS metadata, and path math.

---

## 1. Function categories at a glance

| Category | Functions | Used for |
|---|---|---|
| Config reading | `read_terragrunt_config`, `find_in_parent_folders` | env/region layers (L05, L09) |
| Environment | `get_env`, `get_platform` | CI flags, developer overrides |
| AWS metadata | `get_aws_account_id`, `get_aws_caller_identity_*`, `get_aws_region` | account guards, bucket names |
| Paths | `get_terragrunt_dir`, `get_parent_terragrunt_dir`, `path_relative_to_include`, `get_original_terragrunt_dir` | deriving names/keys from folders |
| Terraform OSS | everything Terraform has (`merge`, `upper`, `format`, `file`, `jsondecode`, `try`, `coalesce`…) | general logic |

Terragrunt embeds HCL, so **all Terraform functions work too**. Below are the
Terragrunt-exclusive ones that matter most.

## 2. `read_terragrunt_config` — the layering workhorse

Reads another `.hcl` file and exposes its `locals` (and more):

```hcl
locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  instance_type = local.env.locals.instance_type
}
```

Combine with `merge()` for explicit layering with overrides:

```hcl
locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = merge(
  local.env_config.locals.common_inputs,  # base
  { name = "my-override" },               # unit wins
)
```

## 3. `get_env` — environment variables with defaults

```hcl
locals {
  # get_env(NAME, DEFAULT) — DEFAULT used when unset OR empty.
  deploy_env = get_env("DEPLOY_ENV", "dev")
  debug      = get_env("TG_DEBUG", "false")
}
```

CI usage:

```bash
DEPLOY_ENV=prod terragrunt run-all apply --terragrunt-non-interactive
```

## 4. AWS identity functions — guards & naming

```hcl
locals {
  account_id = get_aws_account_id()              # needs AWS creds!
  region     = get_aws_region()                  # from config/env
  caller_arn = get_aws_caller_identity_arn()
}

# Bucket name that can never collide across accounts:
# remote_state { config = { bucket = "tf-state-${local.account_id}-${local.region}" } }
```

⚠️ These call AWS APIs — they need valid credentials even for `plan`. In CI,
ensure auth happens before Terragrunt runs.

## 5. Path functions — derive, don't hardcode

Given `live/prod/us-east-1/vpc/terragrunt.hcl` including `live/terragrunt.hcl`:

| Function | Returns |
|---|---|
| `get_terragrunt_dir()` | `.../live/prod/us-east-1/vpc` (this unit's dir) |
| `get_parent_terragrunt_dir()` | `.../live/prod/us-east-1` (parent config's dir) |
| `path_relative_to_include()` | `prod/us-east-1/vpc` (relative to included parent) |
| `basename(get_parent_terragrunt_dir())` | `us-east-1` (classic region trick) |
| `get_original_terragrunt_dir()` | dir where YOU ran the command (differs under `run-all`) |

The classics, used everywhere in this course:

```hcl
locals {
  env    = basename(dirname(get_terragrunt_dir()))  # parent folder name
  region = basename(get_parent_terragrunt_dir())    # e.g. us-east-1
  name   = "acme-${local.env}-${local.region}-vpc"
}
```

## 6. Terraform OSS functions you'll use constantly

```hcl
locals {
  tags     = merge({ ManagedBy = "terragrunt" }, var_extra_tags_like_map)
  upper    = upper(local.env)                        # "DEV"
  short    = substr(uuid(), 0, 8)                    # unique bits
  optional = try(local.maybe.locals.key, "fallback") # safe access
  config   = jsondecode(file("config.json"))         # read JSON files
  name     = format("%s-%s-%02d", "acme", local.env, 3)
}
```

## 7. This lesson's example (runnable, no cloud)

```
12-functions/live/dev/demo/terragrunt.hcl  # get_env, path math, merge, conditionals
12-functions/live/dev/env.hcl              # common_inputs layer
12-functions/modules/demo/
```

```bash
cd live/dev/demo
terragrunt apply                    # defaults
DEPLOY_COLOR=blue terragrunt apply  # env override in action 🎨
terragrunt destroy
```

Open the wrapper and match each output line to the function that produced it.

---

## ✏️ Exercises

1. Run the example with and without `DEPLOY_COLOR` set. Trace the value flow.
2. Add a `get_env("REPLICAS", "1")` override that beats `env.hcl`. Which wins
   when both are set? Why? (Hint: look at the `merge()` order.)
3. Print `get_terragrunt_dir()` vs `get_parent_terragrunt_dir()` in a wrapper
   and confirm the paths from the table above.

## ✅ Key takeaways

- `read_terragrunt_config` + `find_in_parent_folders` = config layering.
- `get_env` = env overrides with defaults. AWS fns = identity-aware naming/guards.
- Path fns let folders BE the configuration (derive env/region from location).

Next 👉 [Lesson 13 — Capstone Project](../13-capstone-project/README.md)
