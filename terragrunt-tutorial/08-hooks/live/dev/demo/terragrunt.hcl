# Lesson 08 — hooks + extra_arguments + retries in one wrapper.
# Run `terragrunt apply` and watch the hooks fire around Terraform.

# Fires BEFORE terraform plan/apply: stamps a marker file + logs a line.
before_hook "announce" {
  commands = ["apply", "plan"]
  execute = [
    "sh", "-c",
    "echo '[before_hook] starting ${get_terragrunt_dir()}...' && date > hook-marker.txt"
  ]
}

# Fires AFTER a SUCCESSFUL apply: pretend notification step.
after_hook "notify" {
  commands = ["apply"]
  execute  = ["echo", "[after_hook] apply succeeded! (here you'd curl Slack)"]
}

# Fires when plan/apply FAILS: pretend alert step.
error_hook "alert" {
  commands = ["apply", "plan"]
  execute  = ["echo", "[error_hook] command failed! (here you'd page on-call)"]
}

# Always pass -lock-timeout to these commands (visible in debug logs).
extra_arguments "lock_timeout" {
  commands  = ["apply", "plan", "destroy"]
  arguments = ["-lock-timeout=5m"]
}

# Auto-retry these flaky errors instead of failing the run.
retryable_errors = [
  "(?s).*connection reset.*",
  "(?s).*Throttling.*"
]

terraform {
  source = "../../../modules/demo"
}

inputs = {
  environment = "dev"
}
