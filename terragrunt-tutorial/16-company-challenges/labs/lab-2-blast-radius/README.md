# Lab 2 — Blast radius: a guard that stops prod accidents 🛡️

**Simulates:** Challenge 5 — running the wrong command against prod.
**Time:** ~10 min · **Cost:** free (local provider).

## The setup

Two identical units, one difference:

| Unit | Guard |
|---|---|
| `live/dev/app` | none — dev applies freely (like auto-apply in CI) |
| `live/prod/app` | `before_hook` **blocks** `apply`/`destroy` unless `CONFIRM_PROD=YES-I-AM-SURE` |

This mirrors the real layered defense: separate accounts + `allowed_account_ids`
+ human approval ([L09](../../../09-environments/README.md),
[L13](../../../13-capstone-project/README.md), [L15](../../../15-cicd-pipelines/README.md)).

## Steps

### 1. Dev applies freely
```bash
cd live/dev/app
terragrunt apply  # works immediately ✅
terragrunt destroy
```

### 2. Prod apply gets BLOCKED ⛔
```bash
cd ../prod/app   # (from live/dev/app → live/prod/app)
terragrunt apply
# ❌ STOPPED by the before_hook: "PROD GUARD: set CONFIRM_PROD=YES-I-AM-SURE..."
# Terraform NEVER RAN — the hook exits 1 first. Nothing changed. That's the point.
```

### 3. Deliberate prod deploy (explicit confirmation)
```bash
CONFIRM_PROD=YES-I-AM-SURE terragrunt apply  # ✅ hook passes, Terraform runs
CONFIRM_PROD=YES-I-AM-SURE terragrunt destroy
```

### 4. Break it on purpose (learning moment)
```bash
CONFIRM_PROD=yes terragrunt plan   # works — plan is read-only, guard only wraps apply/destroy
CONFIRM_PROD=no  terragrunt apply  # blocked — any value except the exact phrase fails
```

## What you just proved
- A `before_hook` can gate dangerous commands **before Terraform starts**.
- Read-only commands (`plan`) stay frictionless; mutating ones require intent.
- In production this pattern becomes: OIDC role per env + `allowed_account_ids` +
  GitHub Environment approvers (no laptop applies to prod at all).

## Cleanup
Both units destroyed in steps 1 and 3 — `git status` should show no stray `.txt` files.
