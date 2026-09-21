# Lesson 02 — Your First terragrunt.hcl

## 🎯 Goal

Write the smallest possible Terragrunt config, run it, and understand **exactly
what happens** when you type `terragrunt apply`.

---

## 1. The example project

```
02-first-terragrunt-config/
├── README.md
├── modules/greeting/          # PURE Terraform module (the "how")
│   ├── main.tf                #   creates one local_file (free, no AWS needed)
│   └── variables.tf
└── live/dev/greeting/         # TERRAGRUNT wrapper (the "what + where")
    └── terragrunt.hcl         #   ~10 lines: source + inputs
```

This example uses the **`local` provider** (writes a text file on disk), so you
can run it with **zero cloud cost and zero credentials**.

## 2. The two files, explained line by line

### File A — the Terraform module (`modules/greeting/main.tf`)

Plain Terraform — nothing Terragrunt-specific. Notice what is **missing**:

- ❌ No `backend "s3"` block (Terragrunt will inject remote state later).
- ❌ No `provider "aws"` with hardcoded keys.
- ❌ No environment names hardcoded — everything comes via `variable`s.

```hcl
variable "message" { type = string }      # Terragrunt will fill these in
variable "environment" { type = string }

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-${var.environment}.txt"
  content  = var.message
}
```

A module like this is **reusable**: dev, stage, prod all use it with different
inputs. (Designing such modules is [Lesson 10](../10-modules-catalog/README.md).)

### File B — the wrapper (`live/dev/greeting/terragrunt.hcl`)

```hcl
terraform {
  source = "../../../modules/greeting"
}

inputs = {
  environment = "dev"
  message     = "Hello from Terragrunt!"
}
```

Two blocks — that's the whole lesson:

| Block | Meaning |
|---|---|
| `terraform { source = "..." }` | **Which** Terraform module to deploy. Can be a local path, a git URL, a versioned ref — anything `terraform init` accepts, plus more (see below). |
| `inputs = { ... }` | **Values** for the module's `variable`s. Terragrunt renders these into a `terraform.tfvars` file automatically. No `.tfvars` files to maintain! |

> 🧠 **Mental model:** `terragrunt.hcl` answers *which module + which values +
> where does state live*. The `.tf` module answers *how to build it*.

## 3. What `source` accepts

```hcl
terraform {
  # Local path (what we use in this course)
  source = "../../../modules/greeting"

  # Git repo (pin production to a tag!)
  # source = "git::https://github.com/org/infra-modules.git//vpc?ref=v0.5.0"

  # Any go-getter URL Terraform supports (s3::, gcs::, http(s)::, ...)
}
```

**Best practice:** local paths while developing, **versioned git URLs**
(`?ref=vX.Y.Z`) in production so environments upgrade deliberately.

## 4. Run it — your first wrapper deploy 🚀

```bash
cd live/dev/greeting

terragrunt init
# Terragrunt downloads the module into .terragrunt-cache/ and runs terraform init

terragrunt plan
# Shows: 1 to add (local_file.greeting)

terragrunt apply   # type "yes"
# Creates greeting-dev.txt — open it and read your message!

terragrunt output  # read outputs, exactly like terraform output

terragrunt destroy # type "yes" — cleans up the file
```

### What Terragrunt did behind the scenes (the "wrapping")

```
1. Read live/dev/greeting/terragrunt.hcl
2. Copied ../../../modules/greeting  →  .terragrunt-cache/<hash>/...
3. Rendered inputs into an auto-generated terraform.tfvars.json
4. cd into the cache dir and ran the REAL terraform binary:
       terraform init / plan / apply ...
5. Reported Terraform's result back to you
```

👀 **See it yourself:** run `terragrunt init`, then look inside
`.terragrunt-cache/` — you'll find a full copy of the module plus the generated
inputs file. That cache dir is *where Terraform actually runs*. (It's git-ignored.)

## 5. `terragrunt` vs `terraform` commands

Every Terragrunt command forwards to Terraform after preparation:

| You run | Terragrunt then runs (in the cache dir) |
|---|---|
| `terragrunt init` | `terraform init` |
| `terragrunt plan` | `terraform plan` |
| `terragrunt apply` | `terraform apply` |
| `terragrunt destroy` | `terraform destroy` |
| `terragrunt output` | `terraform output` |
| `terragrunt validate` | `terraform validate` |

Plus Terragrunt-only helpers you'll meet later: `run-all`, `hclfmt`,
`render-json`, `graph-dependencies`.

---

## ✏️ Exercises

1. Change `message` in `live/dev/greeting/terragrunt.hcl`, run
   `terragrunt apply`, and check the file content changed. Notice: you never
   touched the module.
2. Create `live/prod/greeting/terragrunt.hcl` (copy dev, change values).
   Run `plan` there. You just "added an environment" in 30 seconds.
3. After `init`, explore `.terragrunt-cache/` and find the generated
   `terraform.tfvars.json`. Confirm your inputs are in it.
4. Run with debugging once to watch the wrapping happen:
   `terragrunt plan --terragrunt-log-level debug 2>&1 | head -50`.

## ✅ Key takeaways

- `terraform { source }` = **which module**. `inputs` = **which values**.
- Terragrunt copies the module to `.terragrunt-cache/`, renders inputs, then
  calls **real Terraform**.
- Modules stay generic; environments stay tiny.

Next 👉 [Lesson 03 — Remote State Management](../03-remote-state/README.md)
