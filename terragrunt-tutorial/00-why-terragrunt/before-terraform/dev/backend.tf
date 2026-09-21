# BEFORE (plain Terraform) — DEV environment.
# NOTE: this backend block is copy-pasted into EVERY environment,
# and the `key` is hand-edited each time. Forget to change it and two
# environments will share (and corrupt!) one state file.

terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "dev/greeting/terraform.tfstate" # <-- typed by hand ✋
    region         = "us-east-1"
    dynamodb_table = "my-terraform-locks"
    encrypt        = true
  }
}
