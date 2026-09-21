# Lesson 00 — Why Terragrunt? (What & Why)

## 🎯 Goal

Understand **what Terragrunt is**, **why it exists**, and what
**"Terraform wrapper"** means — before writing a single line of HCL.

---

## 1. What is Terragrunt?

> Terragrunt is a **thin wrapper for Terraform** that provides extra tools for
> keeping your configurations **DRY**, managing **remote state**, and handling
> **dependencies between modules**.

"Wrapper" means:

```
┌─────────────────────────────────────────────────┐
│  YOU type:   terragrunt apply                   │
│                  │                              │
│                  ▼                              │
│  TERRAGRUNT does:                               │
│   1. Reads terragrunt.hcl                       │
│   2. Downloads/copies the Terraform module      │
│      pointed to by  terraform { source = ... }  │
│   3. Generates backend.tf / provider.tf if told │
│   4. Renders inputs as terraform.tfvars         │
│   5. Resolves dependency outputs                │
│   6. Runs:  terraform apply  (the real tool!)   │
└─────────────────────────────────────────────────┘
```

**Terragrunt never replaces Terraform.** Under the hood it always calls the
real `terraform` binary. It just *prepares everything* and then delegates.
That is why every `terragrunt <command>` (plan, apply, destroy, output, …)
maps 1:1 to a `terraform <command>`.

---

## 2. The 4 problems Terragrunt solves

### Problem 1 — Copy-pasted backend config (remote state)

With plain Terraform, **every** environment needs a `backend.tf` like this:

```hcl
# live/dev/vpc/backend.tf  (and you repeat this for stage, prod, every region...)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "dev/vpc/terraform.tfstate"   # ← hand-edited per folder!
    region         = "us-east-1"
    dynamodb_table = "my-locks"
    encrypt        = true
  }
}
```

Problems:
- The `key` must be **unique per module** and you type it by hand — easy to
  collide (two modules sharing one state file = disaster).
- Change the bucket name? Edit **50 files**.
- Backend config **cannot use variables**, so you cannot parameterize it.

✅ **Terragrunt fix:** define the backend **once** in a parent config and let
each child auto-generate its unique key:

```hcl
# root terragrunt.hcl (written ONCE)
remote_state {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"  # auto-unique!
    region = "us-east-1"
  }
}
```

👉 Full details: [Lesson 03](../03-remote-state/README.md).

### Problem 2 — Copy-pasted environments (no DRY)

Plain Terraform multi-env usually becomes copy-paste:

```
live/
├── dev/main.tf      # 200 lines, 95% identical...
├── stage/main.tf    # ...to this file
└── prod/main.tf     # ...and this file
```

Fix a bug in `dev`? Now remember to fix it in `stage` and `prod` too. Drift is
guaranteed.

✅ **Terragrunt fix:** write the Terraform module **once** in `modules/`, then
each environment is a **tiny wrapper** with only its own values:

```hcl
# live/prod/vpc/terragrunt.hcl  (the whole file can be ~15 lines)
terraform {
  source = "../../../modules/vpc"   # reuse!
}
inputs = {
  cidr_block = "10.1.0.0/16"        # only what differs
}
```

👉 Full details: [Lesson 05](../05-include-dry/README.md),
[Lesson 10](../10-modules-catalog/README.md).

### Problem 3 — No dependency management between modules

Say an EC2 module needs the VPC's subnet ID. In plain Terraform you must:

1. `terraform apply` the VPC first (manually, in the right order),
2. Copy its output,
3. Paste it as an input to EC2 (manually, error-prone),
   or wire fragile `terraform_remote_state` data sources everywhere.

✅ **Terragrunt fix:** declare the dependency and use its outputs directly:

```hcl
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = { subnet_id = "subnet-mock123" }  # for `plan` before apply
}
inputs = {
  subnet_id = dependency.vpc.outputs.subnet_id    # automatic!
}
```

👉 Full details: [Lesson 06](../06-dependencies/README.md).

### Problem 4 — No orchestration ("apply everything in order")

With 30 modules, plain Terraform means 30 manual `terraform apply` runs in the
correct dependency order. Miss the order → failures.

✅ **Terragrunt fix:** one command applies **everything in dependency order**:

```bash
terragrunt run-all apply   # VPC first, then EC2, then app... automatically
```

👉 Full details: [Lesson 11](../11-run-all/README.md).

---

## 3. Before / After — see it with your own eyes

This folder contains a miniature comparison:

```
00-why-terragrunt/
├── before-terraform/      # plain Terraform: duplicated per environment
│   ├── dev/
│   │   ├── backend.tf     # hand-written, unique key typed manually
│   │   ├── main.tf        # full copy of the module
│   │   └── variables.tf
│   └── prod/
│       ├── backend.tf     # same file, key hand-edited ✋ risky
│       ├── main.tf        # full copy again (drift waiting to happen)
│       └── variables.tf
└── after-terragrunt/      # same infra, DRY with Terragrunt
    ├── terragrunt.hcl     # root: backend defined ONCE
    ├── modules/greeting/  # Terraform module written ONCE
    └── live/
        ├── dev/terragrunt.hcl   # ~10 lines: source + inputs
        └── prod/terragrunt.hcl  # ~10 lines: source + inputs
```

Open both sides and count the duplicated lines. That's the whole pitch.

### Concept map (how the pieces fit)

```
┌──────────────┐   terraform { source }   ┌──────────────────┐
│ terragrunt   │ ───────────────────────▶ │  terraform       │
│   .hcl       │                          │  module (.tf)    │
│  (WRAPPER:   │   inputs = { ... }       │  (PURE TF:       │
│   where+what)│ ───────────────────────▶ │   how to build)  │
└──────────────┘                          └──────────────────┘
       │ remote_state / generate / hooks / dependencies
       ▼
 "wrapper magic" Terragrunt does BEFORE calling terraform
```

---

## 4. When should you NOT use Terragrunt?

Be honest about trade-offs:

| Use Terragrunt ✅ | Skip Terragrunt ❌ |
|---|---|
| Many environments (dev/stage/prod) or regions | A single tiny stack |
| Many modules with dependencies | One `main.tf`, no reuse needed |
| Team needs enforced backend/locking conventions | Learning Terraform itself (learn TF first!) |
| You want `run-all` orchestration | Your org standardized on Terraform Cloud / Spacelift stacks |

**Rule of thumb:** if you catch yourself copy-pasting `.tf` files between
folders, you have outgrown plain Terraform — that's Terragrunt time.

---

## ✏️ Exercises

1. Open `before-terraform/dev/main.tf` and `before-terraform/prod/main.tf`.
   List every line that is duplicated. Now open
   `after-terragrunt/live/dev/terragrunt.hcl` — how many lines is the whole env?
2. In `after-terragrunt/terragrunt.hcl`, find where the backend is defined.
   How many backend definitions exist for both environments combined?
3. Explain to a friend in one sentence: "Terragrunt is a ___ for Terraform
   that ___." (Suggested answer at the top of this file.)

## ✅ Key takeaways

- Terragrunt = **thin wrapper**: it prepares config, then calls real Terraform.
- It solves 4 pains: **backend duplication, env duplication, dependencies,
  orchestration**.
- Pattern to remember: **`modules/` (how) + `live/` (what/where)**.

Next 👉 [Lesson 01 — Installation & Setup](../01-installation-setup/README.md)
