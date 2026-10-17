# POC: Fix `Warning: Deprecated attribute` — `data.aws_region.current.name`

Proves the issue, the one-word fix, and how to count every occurrence.

## The warning

```
Warning: Deprecated attribute

  on locals.tf line 6, in locals:
   6:   region = data.aws_region.current.name

The attribute "name" is deprecated. Refer to the provider documentation for details.

(and one more similar warning elsewhere)
```

## TL;DR — the fix

```diff
- region = data.aws_region.current.name
+ region = data.aws_region.current.region
```

That's it. The AWS provider **v6** deprecated the `name` attribute of the
`aws_region` data source in favor of **`region`**. Non-blocking warning today,
removal later — fix it now while it's cheap.

## What's in this POC

```
poc-deprecated-attr/
├── README.md              # ← you are here
├── before/                # ❌ reproduces the warning (provider v6 + .name)
│   ├── versions.tf        #    pins aws >= 6.0 (where the deprecation fires)
│   ├── data.tf
│   ├── locals.tf          #    line 6 = the exact warning from your output
│   └── outputs.tf
├── after/                 # ✅ fixed (provider v6 + .region) — zero warnings
│   ├── versions.tf
│   ├── data.tf
│   ├── locals.tf
│   └── outputs.tf
├── deprecation-gate.yml.example   # copy to .github/workflows/ to enforce (§7)
├── renovate.json                  # copy to repo root for upgrade PRs (§6)
├── renovate-self-hosted.yml.example
└── scripts/
    ├── find-deprecated-region.sh  # counts EVERY occurrence ("their number")
    └── fix-deprecated-region.sh   # auto-fix: dry-run default, --apply writes
```

## 1. Reproduce it (before)

```bash
cd before
terraform init
terraform validate
# 👆 Expect: Warning: Deprecated attribute ... data.aws_region.current.name
```

`validate` alone shows it — no AWS credentials needed, since this warning fires
at config-parse time, before any API call.

## 2. Fix it (after)

```bash
cd ../after
terraform init
terraform validate
# 👆 Expect: Success! The configuration is valid. (no warnings)
```

Diff the two folders — the ONLY functional change is `.name` → `.region` in
`locals.tf` (plus comments).

## 3. "How many are there?" — count every occurrence

Terraform prints the first warning and collapses the rest into
`(and N more similar warnings elsewhere)`. Get the real number mechanically:

```bash
# From the REPO ROOT (scans your code + downloaded modules separately):
./poc-deprecated-attr/scripts/find-deprecated-region.sh .
```

Example output:

```
YOUR CODE: 2 occurrence(s) of data.aws_region.<label>.name
  ./live/dev/env.hcl...            # (illustrative)
DOWNLOADED MODULES (.terraform/): 3 occurrence(s)
TOTAL: 5  → fix the 2 in your code, upgrade modules for the other 3
```

Two buckets, two different fixes:

| Bucket | Meaning | Fix |
|---|---|---|
| Your `.tf` files | Code you own | `.name` → `.region` (this POC) |
| `.terraform/modules/...` | Upstream registry/git modules | **Upgrade the module version** — never hand-edit (it re-downloads). If no fixed release exists, temporarily pin `aws ~> 5.0` for that stack. |

> 🔎 The default scan deliberately includes this POC's own repro
> (`before/locals.tf:6`) so you can watch it work. CI mode (`--check`, §7)
> excludes that folder and fails on anything else.

## 4. ⚠️ The version trap (read before you edit!)

- `.region` **does not exist on provider v5** — so on v5, `.name` is correct
  and warning-free. The warning means you're already on **v6+**.
- Therefore: **fix and upgrade go together.** If some stacks still pin v5, leave
  their `.name` alone until you upgrade those stacks to v6.
- Recommended constraint going forward:

```hcl
aws = {
  source  = "hashicorp/aws"
  version = ">= 6.0"
}
```

## 5. Checklist to close this out

- [ ] Run the counter script — note the total number
- [ ] Fix your own files (`.name` → `.region`), `validate` clean
- [ ] For `.terraform/modules/` hits: bump those module versions, `init -upgrade`
- [ ] Re-run the counter → expect `TOTAL: 0`
- [ ] Optional: add the script to CI ([Lesson 15](../terragrunt-tutorial/15-cicd-pipelines/README.md))
      so deprecated patterns fail the PR instead of surprising you later

## Bonus: other v6 renames worth grepping

| Old (warns on v6) | New | Counter | Fixer |
|---|---|---|---|
| `data.aws_region.current.name` | `data.aws_region.current.region` | ✅ | ✅ auto |
| `aws_s3_bucket.*.region` | `aws_s3_bucket.*.bucket_region` | ✅ | ✅ auto |
| `aws_eip` with `vpc = true` | `domain = "vpc"` | ✅ flags it | 🖐️ manual only — sed can't confirm the resource type, so the script refuses to guess |

Paste your "one more similar warning" (the full text) if it doesn't match the
table — same hunt-and-replace loop applies.

## 6. What about Renovate? 🤖

[Renovate](https://docs.renovatebot.com/) is the dependency-update bot that should
own the *upgrade* half of this story. What it would have done for THIS issue:

```
AWS provider 6.0 released
        │ Renovate opens PR: "Update terraform aws to v6"
        ▼
CI plan job runs on that PR (Lesson 15)
        │ plan output shows: data.aws_region.current.name is deprecated ⚠️
        ▼
You fix .name → .region IN THE SAME PR, plan goes clean, merge ✅
```

Same for the `.terraform/modules/` bucket: when upstream modules ship fixed
releases, Renovate's module-bump PRs carry them in — no manual version hunting.

**What Renovate does NOT do:** rewrite your code. It upgrades *versions* and
surfaces the warnings in reviewable PRs; the `.name` → `.region` edit is still
yours (Sections 1–3 above). Think: Renovate = upgrade delivery, you = fix author.

### Setup (pick one)

**Option A — Hosted app (recommended, 5 min):**
1. Install `github.com/apps/renovate` on your repo/org.
2. Copy this POC's [`renovate.json`](renovate.json) to your **repo root**.
3. Merge Renovate's onboarding PR. First Terraform PRs arrive next Monday <6am IST.

**Option B — Self-hosted:** no app install; instead copy
[`renovate-self-hosted.yml.example`](renovate-self-hosted.yml.example) to
`.github/workflows/renovate.yml` (drop `.example`, set latest action version,
add `RENOVATE_TOKEN` secret). Same `renovate.json` drives both options.

### What this `renovate.json` does (read it top to bottom)

| Block | Why |
|---|---|
| `extends: config:recommended` | Sane defaults (conventional commits, conflict handling, onboarding) |
| `schedule` + `timezone` | Update PRs land Monday early morning, not Friday evening |
| `enabledManagers: terraform, regex` | Only Terraform providers/modules + our Terragrunt matcher run |
| Group `hashicorp/aws` | One PR per provider release, not one per folder |
| Majors: no automerge + `needs-plan-review` | v5→v6-style jumps always get human + plan review (deprecations hide in majors!) |
| Patches: automerge | Safe fixes merge themselves once the plan job passes |
| `regexManagers` for `terragrunt.hcl` | Renovate has no native Terragrunt manager, so this regex watches `source = "git::...?ref=vX.Y.Z"` pins and proposes tag bumps — exactly the Lesson 10 promotion flow, automated |
| `prBodyNotes` | Every Terraform PR reminds reviewers to check plan output for deprecations |

Verify your config any time: `npx --yes renovate-config-validator` (or the
"Validate" step Renovate adds to its onboarding PR).

## 7. From POC to enforced practice (auto-fix + CI gate) 🛡️

Finding occurrences by hand doesn't scale. The full loop this POC now ships:

```
┌─────────┐    ┌────────┐    ┌──────┐    ┌──────────┐
│ Counter │───▶│ Fixer  │───▶│ Gate │───▶│ Renovate │
└─────────┘    └────────┘    └──────┘    └──────────┘
 find them      fix them     block        deliver future
 (grep)         (sed)        regressions  upgrades as PRs
```

### Auto-fix (dry-run by default)

```bash
# See what WOULD change (writes nothing):
./poc-deprecated-attr/scripts/fix-deprecated-region.sh .

# Actually rewrite:
./poc-deprecated-attr/scripts/fix-deprecated-region.sh --apply .
# Then: terraform validate  → clean, and the counter → TOTAL: 0
```

Safety rules baked into the fixer:
- **Dry-run unless `--apply`** — you always preview first.
- **Never touches `.terraform/`** — upstream hits are reported, not edited
  (upgrade those modules instead).
- **Never touches `before/`** — the intentional repro survives.
- **v6-only warning** — reminds you `.region` doesn't exist on provider v5.
- **Two safe renames, one refusal** — `aws_region .name` and `s3 bucket .region`
  are auto-fixed (anchored patterns, provably safe); `vpc = true` is only
  *flagged* for manual review since the resource type can't be proven by grep.
- **Re-scans after writing** and reports leftovers (re-run if any).

### Try the fixer safely (2-minute demo, zero risk to the POC)

```bash
rm -rf /tmp/fixdemo && mkdir -p /tmp/fixdemo && cp -r poc-deprecated-attr/before /tmp/fixdemo/
./poc-deprecated-attr/scripts/find-deprecated-region.sh /tmp/fixdemo   # TOTAL: 1
./poc-deprecated-attr/scripts/fix-deprecated-region.sh /tmp/fixdemo    # dry-run preview
./poc-deprecated-attr/scripts/fix-deprecated-region.sh --apply /tmp/fixdemo  # ✏️ fixed
./poc-deprecated-attr/scripts/find-deprecated-region.sh /tmp/fixdemo   # TOTAL: 0 ✅
diff poc-deprecated-attr/before/locals.tf /tmp/fixdemo/before/locals.tf  # see the one-word change
```

### CI gate (activate in 30 seconds)

Copy [`deprecation-gate.yml.example`](deprecation-gate.yml.example) to
`.github/workflows/deprecation-gate.yml` (drop the `.example` suffix) and push.
It runs on every PR touching `*.tf` and **fails the PR** if any new
`data.aws_region.<label>.name` appears in own code. No secrets, no AWS, no
Terraform needed — pure grep, finishes in seconds. (Shipped as an `.example`
because workflow files require the `workflows` permission to push — copy it from
your own machine.) The `before/` repro is allow-listed in `--check` mode, so the
gate stays green while the demo survives.

```bash
# Run the exact gate locally before pushing:
./poc-deprecated-attr/scripts/find-deprecated-region.sh --check .
# ✅ CI gate passed — no deprecated .name in own code.
```
