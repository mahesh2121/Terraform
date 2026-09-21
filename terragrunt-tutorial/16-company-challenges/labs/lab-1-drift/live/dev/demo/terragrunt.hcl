# LAB 1 wrapper — deploy, then hand-edit the file to simulate ClickOps.
# See labs/lab-1-drift/README.md for the step-by-step.

terraform {
  source = "../../../modules/driftdemo"
}

inputs = {
  environment = "dev"
  message     = "managed by terraform"
  owner       = "platform-team"
}
