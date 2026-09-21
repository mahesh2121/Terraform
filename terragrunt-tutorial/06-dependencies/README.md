# Lesson 06 — Dependencies (wiring modules together)

## 🎯 Goal

Connect units so one can consume another's outputs — with correct ordering,
no manual copy-paste, and working `plan` before anything is applied.

---

## 1. The problem, concretely

Your `app` needs the `vpc`'s subnet ID. Plain Terraform options are all painful:

- Apply VPC, **copy the output by hand**, paste into app's tfvars. 🥱
- `terraform_remote_state` data source in every consumer — verbose, and the
  state path is hardcoded in each one.

Terragrunt's answer: the **`dependency` block**.

## 2. The `dependency` block

```hcl
# live/dev/app/terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"   # relative path to the VPC unit folder

  # What to pretend the outputs are when VPC isn't applied yet,
  # so `plan`/`validate` still work. (More below.)
  mock_outputs = {
    subnet_id = "subnet-mock123"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  subnet_id = dependency.vpc.outputs.subnet_id  # ✅ real value at apply time
}
```

What you get:
1. **Automatic outputs** — `dependency.vpc.outputs.<name>` reads the VPC unit's
   real Terraform outputs (via its state).
2. **Automatic ordering** — `run-all apply` builds VPC before app (Lesson 11).
3. **Working plans** — `mock_outputs` let you `plan` the app before the VPC
   exists.

### `mock_outputs` rules (important!)

- Used ONLY when the dependency has no state yet (never applied) AND the current
  command is in `mock_outputs_allowed_terraform_commands` (default:
  `["plan", "validate"]`... actually default allows all *read* commands; be
  explicit anyway).
- On `apply`, Terragrunt **requires real outputs** — if the dependency was never
  applied, you get a clear error instead of silently deploying mocks. ✅ Safe.
- `mock_outputs_merge_with_state = false` (default): mocks fully replace missing
  state. Set `true` to merge mock keys over whatever real state exists.

## 3. `dependency` vs `dependencies`

| Block | Purpose | Example |
|---|---|---|
| `dependency "vpc" { config_path = "../vpc" }` | Read another unit's **outputs** (implies ordering) | app needs `subnet_id` |
| `dependencies { paths = ["../vpc", "../db"] }` | **Ordering only** — "apply those first, but I need no outputs" | run-all sequencing |

```hcl
dependencies {
  paths = ["../vpc", "../db"]  # run-all applies these before me; no outputs read
}
```

Use `dependency` when you need values, `dependencies` when you only need order.

## 4. Outputs flow, end to end

```
┌──────────────┐  terraform output   ┌───────────────────┐  inputs  ┌──────────────┐
│  vpc unit    │ ──────────────────▶ │ dependency "vpc"  │ ───────▶ │  app module  │
│  output      │   subnet_id=...     │ .outputs.subnet_id│          │  var.subnet  │
│  "subnet_id" │                     │  (in app wrapper) │          │  _id         │
└──────────────┘                     └───────────────────┘          └──────────────┘
```

Requirements on the Terraform side: the upstream module MUST declare a matching
`output "subnet_id"`. No output → `dependency.vpc.outputs.subnet_id` fails with
a clear "output not found" error. Always expose what downstream needs.

## 5. This lesson's example (runnable, no cloud)

```
06-dependencies/
└── live/dev/
    ├── network/terragrunt.hcl   # "upstream": writes a fake network-id file, outputs network_id
    └── app/terragrunt.hcl       # "downstream": dependency on ../network, uses network_id
└── modules/{network,app}/       # local-provider modules
```

Run in order (or cheat with `run-all` — Lesson 11 will explain it):

```bash
cd live/dev/network && terragrunt apply      # upstream first
cd ../app && terragrunt plan                 # works thanks to real outputs now
terragrunt apply                              # app file contains the REAL network_id
```

Then experiment: `destroy` both, and run `plan` in `app` FIRST — it succeeds
using `mock_outputs`. Now run `apply` in `app` first — it fails loudly,
telling you to apply `network`. That fail-safe is the feature. 🛡️

## 6. Banishing `terraform_remote_state`

Before Terragrunt, consumers did this inside `.tf` files:

```hcl
# ❌ OLD WAY — don't do this anymore
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "dev/vpc/terraform.tfstate"   # hardcoded path in EVERY consumer
    region = "us-east-1"
  }
}
```

Every consumer hardcodes the producer's state path — rename a folder and N files
break. With `dependency`, the path lives in ONE place (`config_path`), mocks
make plans work, and ordering is automatic. Delete your `terraform_remote_state`
blocks with confidence.

---

## ✏️ Exercises

1. Apply `network`, then `app`. Open the app's file — verify it holds the real
   `network_id`, not the mock.
2. Destroy both. Run `terragrunt plan` in `app` — confirm mocks kick in.
   Then try `terragrunt apply` in `app` — read the error message carefully.
3. Add a second output (`cidr_block`) to the network module + mock, consume it
   in `app`. Note every file you touched (should be 3: module output, mock, input).

## ✅ Key takeaways

- `dependency` = read outputs + get ordering. `dependencies` = ordering only.
- `mock_outputs` make `plan` work pre-apply; `apply` demands real outputs.
- Upstream modules must declare `output`s for everything downstream needs.

Next 👉 [Lesson 07 — Generate Blocks](../07-generate/README.md)
