# AFTER (Terragrunt) — ROOT config, written ONCE for all environments.
# Every child (dev, prod, ...) inherits this via `include`.
# The state key is AUTO-GENERATED per folder — no hand-editing, no collisions.

remote_state {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    # path_relative_to_include() = e.g. "dev" or "prod" automatically.
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-locks"
    encrypt        = true
  }
}
