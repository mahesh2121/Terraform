# BEFORE (plain Terraform) — PROD environment.
# Same file as dev/backend.tf — except ONE hand-edited line (key).
# Change the bucket name? You must edit this file AND every other copy.

terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/greeting/terraform.tfstate" # <-- hand-edited again ✋
    region         = "us-east-1"
    dynamodb_table = "my-terraform-locks"
    encrypt        = true
  }
}
