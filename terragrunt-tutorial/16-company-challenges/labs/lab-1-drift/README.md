# Lab 1 — Drift: catch a ClickOps edit with `plan` 🕵️

**Simulates:** Challenge 2 — someone changed infrastructure outside Terraform.
**Time:** ~10 min · **Cost:** free (local provider).

## Steps

### 1. Deploy the baseline
```bash
cd live/dev/demo
terragrunt apply  # type "yes"
cat "$(terragrunt output -raw file_path)"   # the managed file (lives under .terragrunt-cache)
```

### 2. Play the villain 🦹 — make a ClickOps edit
Terraform tracks the file content. Edit it behind Terraform's back, exactly like a
console tweak:
```bash
# Append a manual change directly to the managed file:
FILE="$(terragrunt output -raw file_path)"
echo "MANUAL HOTFIX (not in code!)" >> "$FILE"
cat "$FILE"   # 👆 your "console edit" is now live — and unknown to Terraform
```

### 3. Detect it like the nightly drift job does
```bash
terragrunt run-all plan -detailed-exitcode --terragrunt-non-interactive
echo "exit code: $?"   # 2 = drift found (this is what drift.yml reacts to!)
```
Read the diff: Terraform wants to **remove** your manual line. That's drift detection. ✅

### 4. Respond (pick ONE, per the [drift runbook](../../runbooks/drift-response-runbook.md))
- **Revert (unauthorized change):** `terragrunt apply` → code wins, manual edit gone.
  Verify: re-run `plan` → exit code `0`, empty diff.
- **Codify (the hotfix was correct):** put the change into `inputs` in
  `terragrunt.hcl` (edit `message`), `apply`, verify clean plan.

## What you just proved
- `plan` is a drift detector; `-detailed-exitcode` makes it machine-readable (CI).
- The only two valid responses: **revert via apply** or **codify via PR**.
- This exact loop is what Lesson 15's `drift.yml` automates nightly.

## Cleanup
```bash
terragrunt destroy  # type "yes"
```
