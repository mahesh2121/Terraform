# AFTER (Terragrunt) — DEV is now just a THIN WRAPPER (~10 lines).
# Compare with the 3 duplicated files it replaces in before-terraform/dev/.

include "root" {
  path = find_in_parent_folders() # inherit the backend from the root config
}

terraform {
  source = "../../modules/greeting" # reuse the module written once
}

inputs = {
  environment = "dev"
  message     = "Hello from DEV"
}
