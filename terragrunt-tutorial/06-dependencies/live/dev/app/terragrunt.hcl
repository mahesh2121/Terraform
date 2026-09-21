# DOWNSTREAM unit — depends on ../network and consumes its outputs.
# Try: 1) plan here BEFORE applying network  → mock outputs used ✅
#      2) apply here BEFORE applying network → clear error 🛡️
#      3) apply network, then plan/apply here → REAL outputs used 🎉

dependency "network" {
  config_path = "../network"

  # Pretend values so `plan`/`validate` work before network exists.
  mock_outputs = {
    network_id = "net-MOCK"
    cidr_block = "0.0.0.0/0"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

terraform {
  source = "../../../modules/app"
}

inputs = {
  environment = "dev"
  # At apply time this is the REAL output read from network's state.
  network_id = dependency.network.outputs.network_id
}
