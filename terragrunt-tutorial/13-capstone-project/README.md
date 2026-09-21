# Lesson 13 — Capstone Project (real-world AWS stack)

## 🎯 Goal

Build a **complete, professional Terragrunt project**: multi-env AWS
infrastructure (VPC + EC2 + S3) using **every concept** from Lessons 00–12.

> ⚠️ **This lesson creates REAL AWS resources** (VPC, EC2 `t3.micro`, S3).
> Cost is ~$0.01/hr for the instance + pennies for the rest.
> **Always `run-all destroy` when finished.** Everything else in this course was
> free; this is the graduation exercise. 🎓

---

## 1. Architecture

```
live/dev/us-east-1/                          AWS (us-east-1)
├── vpc/terragrunt.hcl     ───────────────▶  VPC 10.0.0.0/16, 2 public subnets,
│                                             IGW + route table
├── ec2/terragrunt.hcl     ───────────────▶  t3.micro + SG (SSH/HTTP),
│   (dependency → ../vpc)                     placed in vpc's subnet ✅
└── assets/terragrunt.hcl  ───────────────▶  private S3 bucket (versioned in prod)

live/prod/us-east-1/ — identical structure, prod values (bigger instance,
3 subnets' worth of CIDRs ready, versioning on, monitoring on)
```

Concept map — where each lesson lives in this project:

| Lesson | Where it appears |
|---|---|
| 02 `terraform.source` + `inputs` | every unit |
| 03 `remote_state` | root `terragrunt.hcl` (S3 + DynamoDB) |
| 04 `locals` | root + units (naming, tags, conditionals) |
| 05 `include` root/env/region | every unit |
| 06 `dependency` + mocks | `ec2 → vpc` |
| 07 `generate` provider | root (region + `allowed_account_ids` guard) |
| 08 hooks + retries | root (`retryable_errors`, fmt guard hook) |
| 09 env/region layers | `env.hcl`, `region.hcl` per env |
| 10 module catalog | `modules/{vpc,ec2,s3-bucket}` (generic, versioned-ready) |
| 11 `run-all` | deploy/destroy whole env in one command |
| 12 functions | `get_aws_account_id`, `get_env`, path math, `merge` |

## 2. Project tree

```
13-capstone-project/
├── README.md
├── terragrunt.hcl              # ROOT: backend, provider gen, retries, common tags
├── modules/
│   ├── vpc/                    # main.tf, variables.tf, outputs.tf
│   ├── ec2/                    # main.tf, variables.tf, outputs.tf
│   └── s3-bucket/              # main.tf, variables.tf, outputs.tf
└── live/
    ├── dev/
    │   ├── env.hcl
    │   └── us-east-1/
    │       ├── region.hcl
    │       ├── vpc/terragrunt.hcl
    │       ├── ec2/terragrunt.hcl
    │       └── assets/terragrunt.hcl
    └── prod/
        ├── env.hcl
        └── us-east-1/
            ├── region.hcl
            ├── vpc/terragrunt.hcl
            ├── ec2/terragrunt.hcl
            └── assets/terragrunt.hcl
```

## 3. Setup (do once)

**a) Bootstrap remote state** (Lesson 03) — one bucket + lock table:

```bash
export AWS_REGION=us-east-1
aws s3api create-bucket --bucket <YOUR-UNIQUE>-tf-state --region us-east-1
aws s3api put-bucket-versioning --bucket <YOUR-UNIQUE>-tf-state \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

**b) Edit the root `terragrunt.hcl`:** set YOUR `bucket`, `dynamodb_table`,
and both envs' `account_id` in `live/*/env.hcl`:

```bash
# find your account id:
aws sts get-caller-identity --query Account --output text
```

**c) SSH key (for EC2):** either create one or set `key_name = ""`… the module
makes the key optional — without it you use SSM/Session Manager. Simplest for
learning: leave it empty.

## 4. Deploy (the fun part 🚀)

```bash
cd live/dev/us-east-1

# 1) See the dependency graph (ec2 waits for vpc; assets is independent)
terragrunt graph-dependencies

# 2) Plan EVERYTHING at once (mocks cover ec2's vpc outputs on first run)
terragrunt run-all plan

# 3) Deploy the whole environment with ONE command
terragrunt run-all apply
# Creates: VPC → (EC2 + S3), in dependency order. Get ☕.

# 4) Prove it worked
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" \
  --query "Reservations[].Instances[].PublicIpAddress"

# 5) Tear it ALL down (reverse order, one command) — DO NOT SKIP THIS
terragrunt run-all destroy
```

Then repeat for `live/prod/us-east-1` to feel the promotion flow (Lesson 09):
same modules, same commands — only values change.

## 5. What makes this "production-shaped"?

- **Blast-radius isolation:** dev and prod are separate folders → separate state
  files (separate AWS accounts in a real org — just change `env.hcl`).
- **Account guard:** generated provider pins `allowed_account_ids`, so running
  dev config with prod credentials fails instantly instead of deploying wrong.
- **No hardcoded regions/AMIs:** region comes from `region.hcl`; AMI is looked
  up via a data source (latest Amazon Linux 2) — no stale AMI IDs.
- **Version-ready modules:** swap `source` to `git::...?ref=vX.Y.Z` per env when
  you split repos (Lesson 10).

## 6. Suggested extensions (keep learning!)

1. Add a `live/stage` env (copy dev, new account id + values).
2. Add an `eu-west-1` region under dev (copy region folder, new CIDRs).
3. Add an RDS module + a `db` unit that `app`/`ec2` depends on.
4. Wire CI: PR → `run-all plan`; merge → `run-all apply --non-interactive`.
5. Split `modules/` into a versioned `infra-modules` repo; pin `?ref=` per env.

---

## ✏️ Exercises

1. Deploy dev end-to-end, then destroy it. Time both commands.
2. Before destroying, run `terragrunt output` in `vpc/` and in `ec2/` — confirm
   ec2's `subnet_id` input equals vpc's `public_subnet_ids[0]` output.
3. Break something safely: change dev's `instance_type` in `env.hcl`, run
   `run-all plan` — confirm only `ec2` shows changes (true DRY isolation).

## ✅ Key takeaways

- A professional repo = root (policy) + env/region layers (values) + units
  (wiring) + catalog (logic).
- One command deploys a whole environment: `run-all apply`. One destroys it.
- Everything you learned composes — no new concepts were needed. You know
  Terragrunt now. 🎉

Next 👉 [Lesson 14 — Cheatsheet & FAQ](../14-cheatsheet-faq/README.md)
