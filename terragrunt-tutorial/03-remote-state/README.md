# Lesson 03 — Remote State Management

## 🎯 Goal

Never hand-write a `backend.tf` again. Learn the `remote_state` block, how
Terragrunt auto-generates unique state keys, and how to bootstrap the S3
bucket + lock table.

---

## 1. Quick refresher: why remote state?

Terraform tracks reality in a **state file**. On a team you must NOT keep it
on your laptop — you store it remotely (AWS S3) with **locking**
(DynamoDB) so two people can't `apply` at once and corrupt it.

Plain Terraform forces you to write this **in every module**:

```hcl
terraform {
  backend "s3" {
    bucket = "..."   # same everywhere, still repeated everywhere
    key    = "..."   # MUST be unique per module — typed by hand 😱
    ...
  }
}
```

And backend blocks **don't accept variables**, so parameterization is impossible.
Terragrunt fixes all of it.

## 2. The `remote_state` block

```hcl
remote_state {
  backend = "s3"          # any backend Terraform supports: s3, gcs, azurerm, ...

  generate = {            # (optional but typical) auto-write backend.tf
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {              # backend settings — and unlike backend.tf,
    bucket = "my-terraform-state"     # THESE accept functions & locals!
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-terraform-locks"
  }
}
```

How it works:

1. Terragrunt renders `config` (functions allowed!),
2. Generates a `backend.tf` inside the cache dir,
3. Runs `terraform init`, which configures the backend from that file.

> You write `remote_state` **once** in the root config; every child inherits it
> via `include` (Lesson 05). Hundreds of modules, one backend definition.

## 3. The magic: `path_relative_to_include()`

This function returns the child's folder path **relative to the included
parent**. Example structure:

```
live/
├── terragrunt.hcl              # root: remote_state defined here
├── dev/
│   ├── vpc/terragrunt.hcl      # path_relative_to_include() → "dev/vpc"
│   └── app/terragrunt.hcl      # → "dev/app"
└── prod/
    └── vpc/terragrunt.hcl      # → "prod/vpc"
```

So `key = "${path_relative_to_include()}/terraform.tfstate"` produces:

| Module | S3 key (auto, unique ✅) |
|---|---|
| `live/dev/vpc` | `dev/vpc/terraform.tfstate` |
| `live/dev/app` | `dev/app/terraform.tfstate` |
| `live/prod/vpc` | `prod/vpc/terraform.tfstate` |

Zero hand-editing, zero collisions. Your S3 bucket mirrors your folder tree:

```
s3://my-terraform-state/
├── dev/vpc/terraform.tfstate
├── dev/app/terraform.tfstate
└── prod/vpc/terraform.tfstate
```

Related helpers: `path_relative_to_include()` (most common),
`get_parent_terragrunt_dir()`, `get_terragrunt_dir()` — more in Lesson 12.

## 4. Bootstrapping: the chicken-and-egg bucket

The S3 bucket + DynamoDB table must exist **before** first use. Bootstrap once
(per account/region) with a small throwaway stack, the console, or CLI:

```bash
# 1. State bucket (versioning + encryption ON — non-negotiable)
aws s3api create-bucket --bucket my-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket my-terraform-state \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket my-terraform-state \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# 2. Lock table
aws dynamodb create-table --table-name my-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

> In production, manage the bootstrap resources with their own versioned
> Terragrunt module too (see the capstone, Lesson 13).

### Per-region / per-account state isolation

Common pattern — bucket name includes account + region so state can't leak
across boundaries:

```hcl
locals {
  account_id = get_aws_account_id()
  region     = get_aws_region() # or: basename(get_parent_terragrunt_dir())
}

remote_state {
  backend = "s3"
  config = {
    bucket = "tf-state-${local.account_id}-${local.region}"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.region
    ...
  }
}
```

## 5. Backend config reference (S3 — the 90% case)

| Key | Recommended | Why |
|---|---|---|
| `bucket` | versioned + encrypted bucket | durability, recovery from bad states |
| `key` | `${path_relative_to_include()}/terraform.tfstate` | unique per unit, mirrors folders |
| `region` | your region | — |
| `encrypt` | `true` | state contains secrets! |
| `dynamodb_table` | lock table | prevents concurrent applies |
| `s3_bucket_tags` / `dynamodb_table_tags` | cost-center tags | findable, billable |

Other backends work the same way — `backend = "gcs"` / `"azurerm"` with their
own `config` keys. Terragrunt just passes `config` through to Terraform.

## 6. Try it in this lesson's example

```
03-remote-state/
├── README.md
├── terragrunt.hcl            # root: remote_state defined ONCE (S3 example)
├── live/dev/greeting/terragrunt.hcl   # inherits backend via include
└── modules/greeting/         # same local module as Lesson 02
```

The `live/dev/greeting` wrapper only adds an `include` — the backend comes free:

```bash
cd live/dev/greeting
terragrunt init   # generates backend.tf in cache, runs terraform init
```

> ⚠️ Running `apply` here needs a **real S3 bucket**, so update the bucket name
> in the root config first (or comment out `remote_state` to use local state
> while learning).

---

## ✏️ Exercises

1. Draw your own folder tree (`live/dev/...`, `live/prod/...`) and write down
   what `path_relative_to_include()` returns in each folder.
2. Change the root `key` to include a prefix, e.g.
   `"states/${path_relative_to_include()}/terraform.tfstate"`, and predict the
   new S3 layout.
3. Bootstrap a real bucket + lock table with the AWS CLI (or console), point
   the root config at them, and run `terragrunt init` in the example.

## ✅ Key takeaways

- `remote_state` = backend defined **once**, inherited everywhere.
- `key = "${path_relative_to_include()}/terraform.tfstate"` = unique state per
  folder, automatically.
- Bootstrap the bucket (versioned + encrypted) and lock table once per
  account/region.

Next 👉 [Lesson 04 — Inputs & Locals](../04-inputs-locals/README.md)
