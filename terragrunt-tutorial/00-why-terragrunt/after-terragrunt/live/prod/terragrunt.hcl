# AFTER (Terragrunt) — PROD is also just a THIN WRAPPER.
# Only the values that DIFFER from dev are written here. Nothing else.

include "root" {
  path = find_in_parent_folders() # inherit the backend from the root config
}

terraform {
  source = "../../modules/greeting" # same module, different inputs
}

inputs = {
  environment = "prod"
  message     = "Hello from PROD"
}
