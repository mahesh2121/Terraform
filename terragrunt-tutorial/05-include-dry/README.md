# Lesson 05 — Include & DRY Hierarchy (the heart of Terragrunt)

## 🎯 Goal

Learn `include` + `find_in_parent_folders()` — the mechanism that lets hundreds
of wrappers share **one** backend, **one** provider, and **common** inputs.

---

## 1. The idea: config inheritance

Every real Terragrunt repo is a **tree of configs**:

```
live/
├── terragrunt.hcl                  # ROOT: backend, provider generation,
│                                   # org-wide inputs (defined ONCE)
├── dev/
│   ├── terragrunt.hcl              # ENV level: dev-wide values (optional)
│   ├── vpc/terragrunt.hcl          # UNIT: includes parents + own inputs
│   └── app/terragrunt.hcl
└── prod/
    ├── terragrunt.hcl              # ENV level: prod-wide values
    ├── vpc/terragrunt.hcl
    └── app/terragrunt.hcl
```

Each child **includes** its parents and inherits everything (remote_state,
generate blocks, inputs…), overriding only what differs. Fix the backend once
at the root → all 200 units pick it up. That's DRY.

## 2. `include` + `find_in_parent_folders()`

```hcl
# live/dev/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()   # walk up until a terragrunt.hcl is found
}
```

- `find_in_parent_folders()` searches parent dirs for the nearest
  `terragrunt.hcl` (the root one). No hardcoded `../../..` paths → you can move
  folders around freely.
- Variants: `find_in_parent_folders("env.hcl")` (find a differently-named file),
  `get_parent_terragrunt_dir()` (returns the dir path itself).

### Multiple includes (root + env layers)

A unit can include **several** parents — typical 3-layer setup:

```hcl
include "root" {
  path   = find_in_parent_folders()        # live/terragrunt.hcl
  expose = true                             # make its locals visible as local.root.*
}

include "env" {
  path   = find_in_parent_folders("env.hcl") # live/dev/env.hcl
  expose = true
}
```

| Argument | Meaning |
|---|---|
| `expose = true` | Parent's `locals` become available as `local.<label>.*` (e.g. `local.env.locals.env_name`). Without it you inherit *behavior* (backend, generate) but can't *read* parent locals. |
| `merge_strategy` | How parent/child `inputs` combine: `shallow` (default, child wins per key) or `deep` (nested maps merge). |

## 3. How merging works (inputs layering)

Parent inputs and child inputs **merge**; child wins on conflict (shallow):

```hcl
# live/terragrunt.hcl (root)
inputs = {
  owner       = "platform-team"
  cost_center = "eng"
}

# live/dev/vpc/terragrunt.hcl (child)
inputs = {
  cidr_block = "10.0.0.0/16"
  # owner + cost_center inherited automatically ✅
  # owner = "someone-else"   # ← would override just this key
}
```

Need explicit control? Use `merge()` yourself:

```hcl
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = merge(
  local.env_vars.locals.common_inputs,  # base layer
  { cidr_block = "10.0.0.0/16" },        # unit layer wins
)
```

(`read_terragrunt_config` is covered fully in Lesson 12.)

## 4. This lesson's example (runnable, no cloud)

```
05-include-dry/
├── terragrunt.hcl                  # ROOT: shared locals + shared inputs
├── live/dev/env.hcl                # ENV layer: dev-wide values
├── live/dev/greeting/terragrunt.hcl  # UNIT: includes root + env, adds own input
└── modules/greeting/               # local provider module
```

Run it:

```bash
cd live/dev/greeting
terragrunt apply   # file contains root + env + unit values merged
cat greeting-dev.txt
terragrunt destroy
```

Open the three configs and trace each value: *root → env → unit*. The unit file
is ~15 lines yet produces a fully-configured deployment.

## 5. Golden rules of hierarchy design

1. **Root** (`live/terragrunt.hcl`): backend, provider generation, org constants.
   No environment specifics.
2. **Env/region layer** (`live/dev/...`, `env.hcl`): one value per environment
   (account IDs, CIDRs, sizes). Small files.
3. **Unit**: `terraform.source` + only its own inputs. If a unit file exceeds
   ~40 lines, something probably belongs in a parent or the module.
4. Prefer `find_in_parent_folders()` over relative `../../` include paths —
   refactoring-proof.

---

## ✏️ Exercises

1. Trace the merge: for each value in the generated `greeting-dev.txt`, note
   whether it came from root, env, or unit.
2. Add `live/prod/env.hcl` + `live/prod/greeting/terragrunt.hcl` (copy dev,
   change `env_name`/`message`). No root changes needed — that's the point.
3. Try `merge_strategy = "deep"` on an include with nested map inputs and
   observe the difference vs default shallow merge.

## ✅ Key takeaways

- `include` + `find_in_parent_folders()` = inheritance; write once, use everywhere.
- `expose = true` lets children read parent `locals`.
- Layer inputs root → env → unit; child wins conflicts.

Next 👉 [Lesson 06 — Dependencies](../06-dependencies/README.md)
