# LAB 2 — PROD: guarded by a before_hook.
# `apply`/`destroy` CANNOT run unless CONFIRM_PROD=YES-I-AM-SURE is set.
# Try without it first — watch Terragrunt stop BEFORE Terraform starts.

before_hook "prod_guard" {
  commands = ["apply", "destroy"]
  execute = [
    "sh", "-c",
    "if [ \"$CONFIRM_PROD\" != \"YES-I-AM-SURE\" ]; then echo '⛔ PROD GUARD: refusing to run. Set CONFIRM_PROD=YES-I-AM-SURE to proceed deliberately.'; exit 1; fi; echo '✅ prod confirmation accepted'"
  ]
}

terraform {
  source = "../../../modules/app"
}

inputs = {
  environment = "prod"
}
