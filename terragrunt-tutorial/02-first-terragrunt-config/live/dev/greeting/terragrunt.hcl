# Your first wrapper: pick a module + give it values. That's it.
# Run from THIS folder:
#   terragrunt init && terragrunt plan && terragrunt apply

terraform {
  source = "../../../modules/greeting"
}

inputs = {
  environment = "dev"
  message     = "Hello from Terragrunt!"
}
