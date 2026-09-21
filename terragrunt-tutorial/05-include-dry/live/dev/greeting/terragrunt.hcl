# UNIT — Lesson 05.
# Includes TWO parents (root + env), reads their locals, adds its own input.
# Final inputs = root inputs + env values + unit values, merged.

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  # Read the env layer explicitly (alternative to a second `include`).
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/greeting"
}

inputs = {
  environment = local.env_vars.locals.env_name # from env.hcl ("dev")
  message     = local.env_vars.locals.message  # from env.hcl
  # org + managed_by are inherited from root inputs automatically ✅
}
