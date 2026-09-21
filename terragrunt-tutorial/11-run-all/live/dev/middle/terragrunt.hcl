# CHAIN 2/3 — runs after ../base, consumes its output.

dependency "base" {
  config_path = "../base"
  mock_outputs = {
    base_id = "base-MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

terraform {
  source = "../../../modules/middle"
}

inputs = {
  environment = "dev"
  base_id     = dependency.base.outputs.base_id
}
