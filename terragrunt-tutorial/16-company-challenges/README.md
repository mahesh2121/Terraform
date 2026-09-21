# Lesson 16 — Real Company Challenges: Problems & Solutions 🏢

## 🎯 Goal

Connect everything you learned to **real problems companies face** — so you can
recognize them, fix them, and talk about them confidently in interviews.

Format per challenge: 🔴 Problem → 🔍 Root cause → ✅ Solution (with lesson
links) → 💬 Interview one-liner.

---

## Challenge 1 — State chaos & stuck locks

🔴 **Problem:** Two engineers `apply` at once and corrupt state. A failed apply
leaves a **stuck DynamoDB lock** and every subsequent run fails with
`Error acquiring the state lock`. Or worse: state lives on someone's laptop and
walks out the door with them.

🔍 **Root cause:** Local state, shared state files across modules, no locking,
no unlock runbook — nobody knows if force-unlocking is safe.

✅ **Solution:**
- One state file per unit via `key = "${path_relative_to_include()}/terraform.tfstate"` ([L03](../03-remote-state/README.md)).
- S3 (versioned + encrypted) + DynamoDB locks, bootstrapped per account/region.
- Practice the 👉 [State Lock Runbook](runbooks/state-lock-runbook.md): verify no
  active apply → `terragrunt force-unlock <ID>` → re-run → postmortem.
- CI queues applies per env (`concurrency` group, [L15](../15-cicd-pipelines/README.md)).

💬 *"We isolate state per unit with remote backends and locking, serialize applies
in CI, and follow a lock runbook so unlocks are safe and audited."*

## Challenge 2 — Drift: dev ≠ stage ≠ prod (and ClickOps)

🔴 **Problem:** Prod was "fixed quickly in the console" 6 months ago; now nobody
dares to `apply` because the plan shows 200 mystery changes. Dev and prod configs
have diverged so much that testing in dev proves nothing.

🔍 **Root cause:** Copy-pasted environments, manual console edits, no promotion
discipline, no drift detection.

✅ **Solution:**
- Single module catalog + thin wrappers; only values differ per env ([L09](../09-environments/README.md), [L10](../10-modules-catalog/README.md)).
- Promotion = promote the **same change** dev → stage → prod ([L13](../13-capstone-project/README.md)).
- Nightly drift detection that opens issues ([L15](../15-cicd-pipelines/README.md) `drift.yml`).
- Team rule: **console is read-only** — every change via PR, or it gets reverted.
- Practice the 👉 [Drift Response Runbook](runbooks/drift-response-runbook.md).

💬 *"We treat the console as read-only, promote identical changes through
environments, and run nightly drift detection that files issues automatically."*

## Challenge 3 — Slow, manual, order-dependent releases

🔴 **Problem:** Deploying takes 30 manual `terraform apply` runs in a wiki-documented
order. New joiners get it wrong; Friday deploys are feared.

🔍 **Root cause:** No dependency modeling, no orchestration, tribal knowledge instead
of code.

✅ **Solution:**
- Model wiring with `dependency` + `mock_outputs` ([L06](../06-dependencies/README.md)).
- Deploy with `terragrunt run-all apply` — order derived from the graph ([L11](../11-run-all/README.md)).
- Automate: PR plan gate → auto-apply dev → approved prod apply ([L15](../15-cicd-pipelines/README.md)).

💬 *"Dependencies are declared in code, so one run-all command deploys in the
correct order, and CI enforces plan-review before anything applies."*

## Challenge 4 — Secrets & credentials leakage ⚠️

🔴 **Problem:** AWS keys hardcoded in `.tf`/`.hcl` files (👀 this repo's
`Nginx/variables.tf` has one — rotate it!), secrets visible in state files and
CI logs, long-lived keys shared over chat.

🔍 **Root cause:** No secrets strategy; treating IaC repos like they can't leak.

✅ **Solution:**
- **Never** put secrets in `inputs`/code — pass via env vars, Vault, AWS Secrets
  Manager, or SOPS-encrypted files ([L04](../04-inputs-locals/README.md) rule).
- CI uses **OIDC (keyless)** AWS auth — no stored keys at all ([L15](../15-cicd-pipelines/README.md)).
- State buckets private + encrypted; state contains secrets — treat `.tfstate`
  as sensitive ([L03](../03-remote-state/README.md)).
- Rotate anything ever committed; enable secret scanning (GitHub push protection).

💬 *"No secrets in code or state — we use a secrets manager plus keyless OIDC
auth in CI, encrypted private state, and push protection to catch accidents."*

## Challenge 5 — Blast radius: one mistake hits prod

🔴 **Problem:** Someone runs the dev stack with prod credentials (or vice versa).
One `apply` deletes the production database. There is no undo button.

🔍 **Root cause:** Shared AWS accounts, no guardrails, same permissions everywhere,
apply-from-laptop culture.

✅ **Solution:**
- **Separate AWS accounts** per env (dev/stage/prod) — the #1 blast-radius control ([L09](../09-environments/README.md)).
- Generated provider pins `allowed_account_ids` — wrong account fails instantly ([L13](../13-capstone-project/README.md)).
- Small units (one concern each) so a bad apply is contained ([L10](../10-modules-catalog/README.md)).
- Prod applies only via gated pipeline with human approval ([L15](../15-cicd-pipelines/README.md)).
- `prevent_destroy` / deletion protection on databases and state buckets.

💬 *"We isolate environments by AWS account, enforce account guards in the
provider, keep units small, and require human approval for production applies."*

## Challenge 6 — Copy-paste modules & versioning hell

🔴 **Problem:** 12 slightly different VPC copies across teams. A security fix means
12 PRs. Nobody knows which env runs which version.

🔍 **Root cause:** No shared catalog, local-path-only sources, no release discipline.

✅ **Solution:**
- One versioned catalog (`infra-modules` repo, git tags `vX.Y.Z`); units pin
  `source = "git::...?ref=vX.Y.Z"` **per env** ([L10](../10-modules-catalog/README.md)).
- Upgrade ladder: new tag → dev → verify → stage → prod. Rollback = pin back.
- Module READMEs with inputs/outputs/example (every catalog module).

💬 *"Shared modules are versioned releases pinned per environment, so upgrades
roll dev-first and rollbacks are a one-line pin change."*

## Challenge 7 — No testing, policy, or cost control

🔴 **Problem:** A typo opens SSH to the world; an396 `m5.24xlarge` appears in dev;
the cloud bill doubles with no explanation.

🔍 **Root cause:** Plan output is eyeballed (or skipped); no automated gates; no
cost visibility at PR time.

✅ **Solution:**
- CI gates: `hclfmt` + `fmt` + `validate` + `run-all plan` must pass ([L15](../15-cicd-pipelines/README.md)).
- Policy-as-code: OPA/Conftest or Checkov rules (e.g. "no `0.0.0.0/0` ingress",
  "encryption required") as required checks.
- Cost gate: Infracost comment on every PR showing $ delta.
- Mandatory tags via generated `default_tags` (Owner, CostCenter) for chargeback ([L07](../07-generate/README.md)).
- Module unit tests with Terratest for the critical catalog modules.

💬 *"Every PR gets format, validate, plan, policy, and cost gates, with mandatory
tags for ownership and chargeback."*

## Challenge 8 — Team collisions & unclear ownership

🔴 **Problem:** Team A edits Team B's security group; two teams' pipelines fight
over one state lock; nobody knows who owns folder `live/prod/mystery/`.

🔍 **Root cause:** Flat layout, no code ownership, over-broad IAM.

✅ **Solution:**
- Ownership by folder (`live/<env>/<region>/<team>-<service>`) + GitHub
  **CODEOWNERS** requiring the owning team's review.
- Least-privilege IAM: teams assume roles scoped to their folders/accounts.
- Per-team state paths (automatic with the standard key scheme, [L03](../03-remote-state/README.md)).
- ADRs (Architecture Decision Records) in the repo for cross-team decisions.

💬 *"Ownership is encoded in the folder structure with CODEOWNERS enforcement and
IAM roles scoped per team and environment."*

## Challenge 9 — No disaster-recovery plan

🔴 **Problem:** "What if the region goes down / the state bucket is deleted?"
Answer: silence, then panic. Backups were never tested.

🔍 **Root cause:** DR treated as "we'll figure it out"; state treated as disposable.

✅ **Solution:**
- State bucket: **versioning + MFA delete + cross-region replication** — a deleted
  state is recoverable in minutes ([L03](../03-remote-state/README.md)).
- Data stores: automated snapshots + tested restore procedure (RTO/RPO written down).
- Multi-region layout ready ([L09](../09-environments/README.md)) so failover is a
  planned motion, not improvisation.
- Game-day drill quarterly: restore state + rebuild dev from scratch, time it.

💬 *"State is versioned and replicated, data has tested restores with defined
RTO/RPO, and we rehearse rebuilds on game days."*

## Challenge 10 — Audit & compliance pressure

🔴 **Problem:** Auditor asks "who changed the prod firewall on March 3rd, and who
approved it?" The answer is spread across chat logs and memory.

🔍 **Root cause:** Changes outside version control; approvals over chat; no artifact trail.

✅ **Solution:**
- **Git is the audit log:** every change is a PR with author + reviewers + plan diff ([L15](../15-cicd-pipelines/README.md)).
- Store plan/apply logs as CI artifacts; ship CloudTrail to a locked audit account.
- Branch protection: required reviews + required plan check = provable four-eyes.
- Tag everything with Owner/Compliance scope for auditor-friendly inventories.

💬 *"Every infrastructure change is a reviewed PR with a stored plan diff, so
who/what/when/approved-by is always one git log away."*

---

## 🪜 Maturity ladder (where is your company?)

| Level | Symptoms | Target state |
|---|---|---|
| 0 — Chaos | ClickOps, local state, keys in chat | Get to 1 immediately |
| 1 — Managed | Terraform in git, remote state, manual applies | [L00–L06] of this course |
| 2 — Automated | DRY multi-env, run-all, CI plan gates | [L07–L15] of this course |
| 3 — Governed | Policy + cost gates, OIDC, drift bots, runbooks | This lesson + L15 |
| 4 — Resilient | Multi-account, tested DR, game days, audit-ready | This lesson, challenges 5/9/10 |

## 🧪 Hands-on labs (all FREE — local provider, no AWS)

Don't just read about incidents — **cause and fix them safely** (~10 min each):

| Lab | Incident simulated | What you'll do |
|---|---|---|
| [lab-1-drift](labs/lab-1-drift/) | ClickOps drift (Challenge 2) | apply → hand-edit the file → `plan -detailed-exitcode` catches it → revert-or-codify |
| [lab-2-blast-radius](labs/lab-2-blast-radius/) | Prod accident (Challenge 5) | prod `apply` blocked by a `before_hook` guard until explicitly confirmed |
| [lab-3-secrets](labs/lab-3-secrets/) | Leaked credentials (Challenge 4) | run `secrets-hunt.sh` (finds REAL leaks in this repo!), then pass secrets via env |
| [lab-4-lock-contention](labs/lab-4-lock-contention/) | Lock fight (Challenge 1) | collide two applies → lock error → recover with `-lock-timeout` |

## ✏️ Hands-on exercises

1. **Drift drill:** complete [lab-1-drift](labs/lab-1-drift/), then classify and close
   it following the [Drift Response Runbook](runbooks/drift-response-runbook.md).
2. **Lock drill:** complete [lab-4-lock-contention](labs/lab-4-lock-contention/), then walk the
   [State Lock Runbook](runbooks/state-lock-runbook.md) step by step.
3. **Blast-radius drill:** on paper, walk the capstone ([L13](../13-capstone-project/README.md))
   and list every guard stopping a dev→prod accident. Find at least 4.
4. **Secrets hunt:** search this repo for `AKIA`, `secret`, `password` — note every hit
   and write the fix for each (rotate, move to secrets manager, gitignore).
5. **Interview prep:** pick 3 challenges above and answer them out loud in 60 seconds
   each using the 💬 one-liners as your closing sentence.

## ✅ Key takeaways

- Companies don't fail on Terraform syntax — they fail on **state, drift, secrets,
  blast radius, and process**.
- Every challenge above maps to a lesson in this course — you already know the fixes.
- Runbooks turn panic into procedure: write them before you need them.

Back to [course index](../README.md) · Bookmark: [Cheatsheet](../14-cheatsheet-faq/README.md)
