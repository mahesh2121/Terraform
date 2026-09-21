# Lesson 15 — CI/CD Pipelines (Level 3 🏭)

## 🎯 Goal

Build a **production CI/CD pipeline** for the capstone project: automatic
`plan` on every PR, `apply` on merge, human approval for prod, keyless AWS
auth (OIDC), and nightly drift detection.

> This is the lesson that turns "I know Terragrunt" into "I ship infra safely
> on a team." Everything here maps to files in this folder that you can copy
> into a real repo's `.github/workflows/`.

---

## 1. The pipeline we're building

```
Pull Request                         Merge to main                    Nightly
    │                                      │                              │
    ▼                                      ▼                              ▼
┌─────────┐  plan.yml               ┌──────────────┐  apply-dev.yml  ┌───────────┐ drift.yml
│ fmt +   │  • run-all plan         │ environment: │  • run-all      │ run-all   │ • plan with
│ validate│    dev + prod           │ dev (auto)   │    apply dev    │ plan prod │   -detailed-
│ + plan  │  • post diff as         └──────────────┘                 └───────────┘   exitcode
└─────────┘    PR comment                   │                         ▲ Changes? │
    │                                       ▼                         │ ─────────┘
    │                               ┌──────────────┐  apply-prod.yml  │ open/update
    │                               │ environment: │  • waits for     │ GitHub issue
    └──────────────────────────────▶│ prod (human  │    HUMAN         │
       merge only if                 │ approval ✅) │    approval      │
       plan is clean                 └──────────────┘                  │
```

**Golden rules of infra CI/CD:**
1. **Nothing applies without a PR plan first.** The plan diff IS the code review.
2. **Humans approve prod, automation applies dev.** Bots do; people decide.
3. **No long-lived AWS keys in CI.** OIDC (keyless) auth only.
4. **Pinned tool versions.** CI installs the exact Terraform/Terragrunt from the repo.

## 2. Files in this lesson

```
15-cicd-pipelines/
├── README.md                    # ← you are here
├── workflows/
│   ├── plan.yml                 # PR → fmt + validate + run-all plan (dev+prod) + PR comment
│   ├── apply-dev.yml            # merge to main → auto-apply dev
│   ├── apply-prod.yml           # manual trigger → apply prod (after approval)
│   └── drift.yml                # nightly → detect drift, open issue if found
├── oidc-trust-policy.json       # IAM trust policy so GitHub can assume AWS roles (keyless!)
└── scripts/
    └── ci-simulate.sh           # run the CI checks LOCALLY (no GitHub/AWS needed)
```

To use in a real repo: copy `workflows/*.yml` → `.github/workflows/`, create the
two IAM roles (§4), and configure two GitHub Environments (§5). Done.

## 3. Workflow tour (open each file and follow along)

### `plan.yml` — the PR gate (most important file!)

Triggers on pull requests touching infra paths. Key techniques:

```yaml
strategy:
  matrix:
    env: [dev, prod]          # plan BOTH envs in parallel
```

- **Pinned versions** via `env:` (`TF_VERSION`, `TG_VERSION`) — one place to bump.
- **`terraform_wrapper: false`** on setup-terraform — the wrapper breaks raw output capture.
- **Terragrunt installed by direct download** — no third-party action dependency.
- **AWS auth via OIDC** (`aws-actions/configure-aws-credentials@v4` with
  `role-to-assume`) — zero stored secrets.
- **Plan output posted as a PR comment** — reviewers see the diff without running anything.
- **`--terragrunt-non-interactive`** everywhere — CI must never prompt.
- **`concurrency` group** cancels stale runs when you push fixes to the PR.

### `apply-dev.yml` — auto-apply on merge

Triggers on `push` to `main` (i.e., merged PRs). Targets **dev only**, using the
`dev` GitHub Environment (which holds the dev role ARN). No human gate — dev
should always reflect `main`.

### `apply-prod.yml` — gated prod deploys

Triggered manually (`workflow_dispatch`, optionally on a schedule/tag). Uses the
`prod` GitHub Environment with **required reviewers** — the run pauses until a
human clicks Approve. This is the "promotion" from Lesson 09, enforced by machinery.

### `drift.yml` — nightly reality check

Scheduled `run-all plan -detailed-exitcode` (exit `2` = changes = drift, since
nobody ran apply). On drift it opens/updates a GitHub issue with the diff.
ClickOps outside Terraform gets caught within 24h. 🕵️

## 4. Keyless AWS auth: GitHub OIDC (do once per AWS account)

Never put `AWS_ACCESS_KEY_ID` in GitHub Secrets. Instead, let AWS **trust GitHub**
directly:

```bash
# 1) One-time per account: register GitHub as an OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2) Edit oidc-trust-policy.json: replace ORG/REPO with yours,
#    then create the role (repeat per account: dev role, prod role)
aws iam create-role --role-name github-terragrunt-dev \
  --assume-role-policy-document file://oidc-trust-policy.json

# 3) Attach permissions — SCOPE THIS DOWN in real life!
#    (Full demo: PowerUser + specific state-bucket/dynamodb rights.
#     Prod: same, but the trust policy ALSO restricts to the prod environment.)
aws iam attach-role-policy --role-name github-terragrunt-dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

The trust policy says: *"only workflows from repo ORG/REPO may assume this role,
only from the listed branches/environments, and AWS verifies GitHub's signed token."*
Short-lived credentials, auto-rotated, nothing to leak. 🔐

## 5. GitHub Environments (do once per repo)

Settings → Environments → create **`dev`** and **`prod`**:

| Environment | Protection rules | Variables |
|---|---|---|
| `dev` | none (auto-apply) | `AWS_ROLE_ARN` = dev role ARN |
| `prod` | ✅ Required reviewers (1–2 people) + `main` branch only | `AWS_ROLE_ARN` = prod role ARN |

Workflows reference them with `environment: dev` / `environment: prod`, and read
the role via `${{ vars.AWS_ROLE_ARN }}`. Approvals, audit logs, and per-env
secrets come free with the platform.

Also enable branch protection on `main`: **require the `plan` workflow to pass**
before merge. Now unplanned infra literally cannot reach `main`. 🛡️

## 6. Try it WITHOUT GitHub or AWS (local CI simulation) 💻

`scripts/ci-simulate.sh` runs the same gates CI would — against the FREE local
Lesson-11 example:

```bash
cd terragrunt-tutorial/15-cicd-pipelines
./scripts/ci-simulate.sh
# ① hclfmt check  ② terraform fmt check  ③ terragrunt validate × units
# ④ run-all plan (the "PR plan")  → prints the diff CI would comment
```

This is also a great **pre-commit hook**: if it fails locally, don't push.

## 7. Operating the pipeline (day-2 notes)

- **Plan ≠ apply drift:** someone merges without re-planning? Require "branches
  up to date" in branch protection, or re-plan in the apply job and fail on diff.
- **Lock contention in CI:** concurrent applies to one env → enable
  `concurrency: group: apply-${{ matrix.env }}` with `cancel-in-progress: false`
  so applies queue instead of overlapping.
- **State bucket errors:** keep `--terragrunt-fail-on-state-bucket-creation-error`
  in mind for first runs; normally the bootstrap (Lesson 03) already exists.
- **Log hygiene:** plans can contain secrets — prefer private repos or redact;
  never `echo` credentials; OIDC tokens are masked automatically.
- **Speed at scale:** later add path-filtering (only plan changed envs),
  dependency-aware ordering is already handled by `run-all` (Lesson 11).

---

## ✏️ Exercises

1. Run `./scripts/ci-simulate.sh`. Break something (typo an input in Lesson 11),
   re-run — confirm CI would have caught it. Fix it.
2. Read `workflows/plan.yml` end-to-end. For each step, answer: "what breaks if
   I delete this step?"
3. On paper: draw what happens from "developer opens PR" to "prod applied",
   naming every workflow + gate + human involved.
4. (With AWS + GitHub) Actually wire it: create the OIDC roles, copy the
   workflows to `.github/workflows/`, open a test PR against the capstone.

## ✅ Key takeaways

- PR → `plan` + diff comment (gate). Merge → auto-apply dev. Prod → human approval.
- OIDC = keyless AWS auth; GitHub Environments = approvals + per-env roles.
- Pin tool versions; `--terragrunt-non-interactive`; nightly drift detection.
- `./scripts/ci-simulate.sh` = the whole gate, runnable on your laptop.

Next 👉 [Lesson 14 — Cheatsheet & FAQ](../14-cheatsheet-faq/README.md) (bookmark it)
· Back to [course index](../README.md)
