# CHAIN 1/3 — no dependencies, always runs first.

terraform {
  source = "../../../modules/base"
}

inputs = {
  environment = "dev"
}
