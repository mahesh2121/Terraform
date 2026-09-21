# UPSTREAM unit — no dependencies. Apply this FIRST.
#   terragrunt apply

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "dev"
  cidr_block  = "10.0.0.0/16"
}
