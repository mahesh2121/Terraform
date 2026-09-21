# Lesson 04 — locals compute values; inputs pass them to Terraform.
# Run (free, local provider): terragrunt apply && terragrunt destroy

locals {
  # Derive the environment from the FOLDER name ("dev") — no hardcoding.
  env = basename(get_parent_terragrunt_dir())

  # Build reusable values once...
  name_prefix = "server-${local.env}"
  common_tags = {
    Environment = local.env
    ManagedBy   = "terragrunt"
  }

  # ...including conditional logic: prod gets more replicas + monitoring.
  is_prod  = local.env == "prod"
  replicas = local.is_prod ? 3 : 1
}

terraform {
  source = "../../../modules/server"
}

inputs = {
  server_name        = local.name_prefix
  instance_type      = local.is_prod ? "t3.medium" : "t3.micro"
  replicas           = local.replicas
  monitoring_enabled = local.is_prod
  tags               = local.common_tags
}
