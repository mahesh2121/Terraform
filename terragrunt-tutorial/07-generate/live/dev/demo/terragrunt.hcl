# Lesson 07 — the wrapper GENERATES provider.tf + versions.tf,
# so the module doesn't need them. Run: init → apply → destroy.

locals {
  environment = "dev"
}

# 1) Generate the provider configuration Terraform requires.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "local" {}
EOF
}

# 2) Generate version constraints (in real AWS repos: required_version +
#    required_providers for aws, enforced identically for every unit).
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
EOF
}

terraform {
  source = "../../../modules/demo"
}

inputs = {
  environment = local.environment
  message     = "Hello from a generated provider!"
}
