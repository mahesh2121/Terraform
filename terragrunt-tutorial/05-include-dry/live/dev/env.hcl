# ENV layer — values shared by all DEV units (but not prod).
# Naming it `env.hcl` (not terragrunt.hcl) means it's found via
# find_in_parent_folders("env.hcl") and is NOT itself a deployable unit.

locals {
  env_name = "dev"
  message  = "Hello from the DEV environment layer!"
}
