# Lab 3 — Secrets: hunt leaks, then do it right 🔑

**Simulates:** Challenge 4 — credentials leaking into git + state.
**Time:** ~10 min · **Cost:** free (scanner runs anywhere; demo uses local provider).

## Part A — Hunt (runs RIGHT NOW, no tools needed)

```bash
# From the REPO ROOT:
./terragrunt-tutorial/16-company-challenges/labs/lab-3-secrets/scripts/secrets-hunt.sh
```

Expected result: **it FINDS real leaks** — an AWS access-key-shaped value in
`Nginx/variables.tf` AND a committed private SSH key (`Nginx/levelup_key`).
Those are your demo findings. 🎯

For each finding, the fix order is always:
1. **Rotate/revoke** the credential (it's compromised — git history never forgets).
2. Remove it from code; load it from a secrets manager / env var instead (Part B).
3. Enable push protection (GitHub: Settings → Code security → Push protection)
   so the next accident is blocked at push time.

## Part B — The right pattern (needs terragrunt + terraform)

The demo wrapper passes a token via **environment variable**, marks it
`sensitive`, and the module proves it can USE it without STORING it
(the file records only `token_configured = true/false` — never the value):

```bash
cd live/dev/token-demo

terragrunt apply            # works, token_configured = false
terragrunt destroy

DEMO_API_TOKEN='s3cr3t!' terragrunt plan
# 👆 Notice: the plan shows "(sensitive value)" — redacted, not echoed.

DEMO_API_TOKEN='s3cr3t!' terragrunt apply
cat "$(terragrunt output -raw status_file)"   # contains true/false, NOT the token
terragrunt destroy
```

## Part C — Production upgrade path (read + understand)

| Level | Pattern |
|---|---|
| Lab (here) | `get_env()` + `sensitive = true`, never persist the value |
| Team | AWS Secrets Manager / Vault **data sources** read at apply time |
| CI | **OIDC keyless auth** — no static credentials exist at all ([L15](../../../15-cicd-pipelines/README.md)) |
| Repo safety | Secret scanning + push protection + `secrets-hunt.sh` as a pre-commit hook |

## What you just proved
- Leaks are findable mechanically — run the scanner in CI and as a git hook.
- Sensitive values can flow through Terragrunt without landing in files/logs.
- The endgame is credentials that **don't exist** (OIDC), not credentials that
  are "carefully managed".
