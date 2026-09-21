# Lesson 08 — Hooks, Extra Arguments & Retries

## 🎯 Goal

Run custom logic **before/after** Terraform commands (`before_hook`,
`after_hook`, `error_hook`), inject CLI flags (`extra_arguments`), and survive
flaky clouds (`retryable_errors`).

---

## 1. Hooks: custom steps around Terraform

```hcl
before_hook "copy_common_vars" {
  commands     = ["apply", "plan"]          # which TF commands trigger this
  execute      = ["cp", "common.tfvars", "extra.tfvars"]
  run_on_error = false                       # skip if a previous hook failed
}

after_hook "notify" {
  commands = ["apply"]
  execute  = ["echo", "apply finished in ${get_terragrunt_dir()}!"]
}

error_hook "alert_on_failure" {
  commands = ["apply", "plan"]
  execute  = ["echo", "FAILED — paging the team..."]
  # Real world: curl your Slack/PagerDuty webhook here
}
```

| Block | Runs… | Typical uses |
|---|---|---|
| `before_hook` | Before Terraform | copy files, run linters (`tflint`), fetch secrets, `terragrunt validate` gates |
| `after_hook` | After successful Terraform | notifications, trigger downstream jobs, write audit logs |
| `error_hook` | If Terraform (or a hook) fails | alerts, cleanup of temp files |

Hooks run in the unit's working dir, and `execute` takes a command + args list
(no shell — wrap in `["sh", "-c", "..."]` if you need pipes/redirects).

## 2. `extra_arguments`: inject Terraform CLI flags

Force (or default) flags for specific commands — e.g. always use a shared
var-file on plan/apply, or always lock-timeout:

```hcl
extra_arguments "common_vars" {
  commands  = ["apply", "plan", "destroy"]
  arguments = ["-var-file=common.tfvars"]
}

extra_arguments "lock_timeout" {
  commands  = ["apply", "plan", "destroy", "init"]
  arguments = ["-lock-timeout=20m"]
}
```

Useful for org-wide guardrails from the **root** config:
`required_var_files`, `env_vars` (inject `TF_VAR_*` / `TF_CLI_ARGS_*`!), and more:

```hcl
extra_arguments "env" {
  commands = ["apply", "plan"]
  env_vars = {
    TF_CLI_ARGS_plan = "-lock=false"   # example: never lock on plan
  }
}
```

## 3. `retryable_errors`: survive eventual consistency

Cloud APIs flake (`Throttling`, `RequestLimitExceeded`, IAM propagation delays).
Instead of re-running by hand, auto-retry matching errors:

```hcl
retryable_errors = [
  "(?s).*RequestLimitExceeded.*",   # regex matched against stderr
  "(?s).*Throttling.*",
  "(?s).*connection reset.*"
]

retry_max_attempts       = 3     # default 3... tune per need
retry_sleep_interval_sec = 10    # wait between attempts
```

Terragrunt re-runs the Terraform command when stderr matches. Put the standard
list in the **root** config so every unit inherits resilience.

## 4. This lesson's example (runnable, no cloud)

```
08-hooks/
├── live/dev/demo/terragrunt.hcl  # before/after/error hooks + extra_arguments
└── modules/demo/                 # local provider module
```

```bash
cd live/dev/demo
terragrunt apply
# 👉 Watch: before_hook echoes + writes a marker file,
#    then Terraform runs, then after_hook echoes.
# To see error_hook: temporarily break an input and run plan.
terragrunt destroy
```

## 5. Putting hooks in the root (real-world pattern)

```hcl
# live/terragrunt.hcl — guardrails for ALL units
before_hook "validate_fmt" {
  commands = ["apply", "plan"]
  execute  = ["sh", "-c", "terraform fmt -check -recursive . || echo 'run terraform fmt!'"]
}

retryable_errors = [
  "(?s).*RequestLimitExceeded.*",
  "(?s).*Throttling.*",
  "(?s).*Failed to lock state.*",  # transient lock contention
]
```

⚠️ Keep hooks **fast and side-effect-light** — they run on every invocation.
Heavyweight CI (security scans, cost estimates) belongs in the pipeline, with
hooks only as local guardrails.

---

## ✏️ Exercises

1. Run `apply` in the example and identify each hook's output in the log.
   Which ran first — the hook or Terraform?
2. Break the config (e.g. typo an input key) and run `plan` — confirm the
   `error_hook` fires.
3. Add an `extra_arguments` block that passes `-lock-timeout=5m` to plan/apply,
   then run with `--terragrunt-log-level debug` and find the flag in the
   Terraform command line.

## ✅ Key takeaways

- `before_hook` / `after_hook` / `error_hook` wrap Terraform with custom steps.
- `extra_arguments` inject CLI flags / env vars per command.
- `retryable_errors` auto-retries flaky cloud errors (regex on stderr).

Next 👉 [Lesson 09 — Multi-Environment Layout](../09-environments/README.md)
