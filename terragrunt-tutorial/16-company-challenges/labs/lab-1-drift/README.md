# Lab 1 — Drift: catch a ClickOps edit with `plan` 🕵️

**Simulates:** Challenge 2 — someone changed infrastructure outside Terraform.
**Time:** ~10 min · **Cost:** free (local provider).

## Steps

### 1. Deploy the baseline
```bash
cd live/dev/demo
terragrunt apply  # type "yes"
cat ../../../../modules/driftdemo/*.txt 2>/dev/null || find $(terragrunt terragrunt-info --json 2>/dev/null | grep -o '"WorkingDir": *"[^"]*"' | head -1) -name '*.txt'
# Simpler: the file lives in the module dir copy under .terragrunt-cache — or just trust plan in step 3.
```

### 2. Play the villain 🦹 — make a ClickOps edit
Terraform tracks the file content. Edit it behind Terraform's back, exactly like a
console tweak:
```bash
# Find the generated file (under .terragrunt-cache) and append a manual change:
find .terragrunt-cache -name 'notice-*.txt' -exec sh -c 'echo "MANUAL HOTFIX (not in code!)" >> "$1"' _ {} \;
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
