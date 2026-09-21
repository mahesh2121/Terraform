# ROOT config — Lesson 03.
# Defines remote state ONCE. Every child under live/ inherits it via:
#   include "root" { path = find_in_parent_folders() }
# (You'll master `include` in Lesson 05; just observe the effect here.)
#
# ⚠️ Replace bucket/table/region with YOUR bootstrap resources before apply.
# Comment out this whole block to fall back to local state while learning.

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = "my-terraform-state"

    # MAGIC LINE: resolves to e.g. "dev/greeting/terraform.tfstate"
    # depending on which child folder is running. Unique per unit, always.
    key = "${path_relative_to_include()}/terraform.tfstate"

    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-terraform-locks"
  }
}
