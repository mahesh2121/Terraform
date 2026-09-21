# LAB 3 wrapper — secret arrives via ENVIRONMENT, never hardcoded.
#   terragrunt apply                        → token_configured = false
#   DEMO_API_TOKEN='x' terragrunt apply     → token_configured = true (value never stored)

locals {
  api_token = get_env("DEMO_API_TOKEN", "")
}

terraform {
  source = "../../../modules/token-demo"
}

inputs = {
  environment = "dev"
  api_token   = local.api_token
}
