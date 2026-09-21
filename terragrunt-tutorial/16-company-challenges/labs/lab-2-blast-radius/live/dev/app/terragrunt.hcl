# LAB 2 — DEV: no guard, applies freely (mirrors CI auto-apply to dev).

terraform {
  source = "../../../modules/app"
}

inputs = {
  environment = "dev"
}
