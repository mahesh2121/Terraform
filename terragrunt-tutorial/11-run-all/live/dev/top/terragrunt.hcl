# CHAIN 3/3 — runs after ../middle, consumes its output.
# From live/dev: `terragrunt run-all apply` → base, middle, top. One command. 🎉

dependency "middle" {
  config_path = "../middle"
  mock_outputs = {
    middle_id = "middle-MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

terraform {
  source = "../../../modules/top"
}

inputs = {
  environment = "dev"
  middle_id   = dependency.middle.outputs.middle_id
}
