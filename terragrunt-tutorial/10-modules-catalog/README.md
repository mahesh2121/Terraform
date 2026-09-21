# Lesson 10 — Reusable Module Catalog (`modules/` vs `live/`)

## 🎯 Goal

Learn to split responsibilities correctly: generic versioned Terraform modules
in `modules/` vs thin environment wrappers in `live/` — the most important
design skill in this course.

---

## 1. The golden split

```
┌─────────────────────────────┐      ┌─────────────────────────────┐
│  modules/  (THE CATALOG)     │      │  live/  (THE DEPLOYMENTS)   │
│  Pure Terraform (.tf)        │      │  Terragrunt wrappers (.hcl) │
│                              │      │                              │
│  • HOW to build a thing      │◀─────│  • WHAT to build, WHERE,     │
│  • Generic, reusable         │source │    with WHICH values        │
│  • No backends, no providers │      │  • One folder = one state    │
│  • Versioned (git tags)      │      │  • Small files (~10-40 lines)│
└─────────────────────────────┘      └─────────────────────────────┘
```

**Test:** could this module deploy to a brand-new AWS account/region/env
tomorrow with only different inputs? If yes → it's a good catalog module.
If it mentions `dev`, `us-east-1`, or bucket names → values leaked into the
module; move them to `live/`.

## 2. Module design rules

1. **No `backend` blocks** — state always comes from Terragrunt (`remote_state`).
2. **No `provider` blocks with values** — providers are generated (Lesson 07).
   Keep only `required_providers` version constraints.
3. **Everything environment-specific is a `variable`** — names, sizes, counts,
   CIDRs, feature flags. Sensible `default`s allowed, required vars for the rest.
4. **`output` everything downstream may need** — ids, ARNs, endpoints
   (Lesson 06 consumers can only read declared outputs).
5. **Validate inputs** — `validation {}` blocks fail fast on bad values
   (this repo's [`variables/`](../../variables/variables.tf) folder shows how).
6. **One concern per module** — `vpc`, `ec2-instance`, `s3-bucket`, `rds`…
   Compose with `dependency`, not by stuffing everything into one module.

## 3. Versioning the catalog (how prod stays safe)

During development, units point at local paths:

```hcl
terraform {
  source = "../../../modules/vpc"
}
```

For production, publish modules to git and **pin versions per environment**:

```hcl
# live/dev/vpc/terragrunt.hcl — dev tries the new version first
terraform {
  source = "git::https://github.com/acme/infra-modules.git//vpc?ref=v0.6.0"
}

# live/prod/vpc/terragrunt.hcl — prod stays on the proven one
terraform {
  source = "git::https://github.com/acme/infra-modules.git//vpc?ref=v0.5.0"
}
```

Upgrade flow: tag `v0.6.0` → roll dev → verify → bump stage → verify → bump prod.
If `v0.6.0` misbehaves in dev, prod never knew it existed. 🛡️

> Keep modules + live in one repo while learning (like this course). Split into
> `infra-modules` + `infra-live` repos when teams grow — the `source` URLs are
> the only thing that changes.

## 4. A well-built catalog module, annotated

See `modules/s3-bucket/` in this lesson — a realistic AWS example:

```hcl
# modules/s3-bucket/variables.tf (contract: everything varies by env)
variable "bucket_name"          { type = string }   # required, no default
variable "versioning_enabled"   { type = bool   default = true }
variable "tags"                 { type = map(string) default = {} }

# modules/s3-bucket/main.tf (logic only — no env knowledge)
resource "aws_s3_bucket" "this" { bucket = var.bucket_name ... }

# modules/s3-bucket/outputs.tf (downstream contract)
output "bucket_id"  { value = aws_s3_bucket.this.id }
output "bucket_arn" { value = aws_s3_bucket.this.arn }
```

And its two thin wrappers (`live/dev/...`, `live/prod/...`) differ only in
`bucket_name` + `versioning_enabled`. Open all five files side by side — this
is the pattern for everything you'll ever build.

> ⚠️ The AWS example creates **real resources** (S3 buckets must be globally
> unique — the wrappers include a random suffix pattern). Only `apply` it with
> AWS credentials, and `destroy` afterwards.

## 5. Catalog checklist (tattoo this on your arm)

- [ ] No backend / provider-with-values / hardcoded env names inside
- [ ] Variables for everything that varies; validation blocks on risky ones
- [ ] Outputs for every id/ARN/endpoint downstream could need
- [ ] `README.md` per module: purpose, inputs, outputs, example wrapper
- [ ] Git-tagged releases (`v0.1.0`…); units pin `?ref=vX.Y.Z` in prod

---

## ✏️ Exercises

1. Open `modules/s3-bucket/*.tf` and verify each checklist item above.
2. Write a wrapper for a new env (`stage`) reusing the module with different
   inputs — no module changes allowed.
3. Take one module from this repo's root (`instance/`, `Nginx/`) and refactor it
   on paper: which lines belong in `modules/`, which in `live/`?

## ✅ Key takeaways

- `modules/` = HOW (generic, versioned). `live/` = WHAT/WHERE/VALUES (thin).
- Good modules: no backend/provider/env names; variables in, outputs out.
- Pin `?ref=vX.Y.Z` per env; promote versions dev → stage → prod.

Next 👉 [Lesson 11 — run-all Orchestration](../11-run-all/README.md)
