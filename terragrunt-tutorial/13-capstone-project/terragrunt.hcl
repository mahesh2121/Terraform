# ═══════════════════════════════════════════════════════════════════
# CAPSTONE ROOT — every policy decisions lives here exactly once:
# remote state (L03), provider generation (L07), retries (L08),
# shared locals/inputs (L04/L05), AWS guards (L12).
# ═══════════════════════════════════════════════════════════════════

locals {
  # Read env + region layers so the ROOT can use them (e.g. account guard).
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  env_name   = local.env.locals.env
  aws_region = local.region.locals.aws_region
  account_id = local.env.locals.account_id

  common_tags = {
    Org         = "acme"
    Environment = local.env_name
    ManagedBy   = "terragrunt"
  }
}

# ── Remote state (L03): one backend for ALL units, unique key per folder ──
# ⚠️ Replace bucket/table with YOUR bootstrap resources before running!
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = "REPLACE-ME-tf-state"

    key = "${path_relative_to_include()}/terraform.tfstate"

    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "tf-locks"
  }
}

# ── Provider generation (L07): same AWS provider (+account guard) everywhere ──
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  # 🛡️ If you run dev config with prod credentials (or vice versa),
  # Terraform fails INSTANTLY instead of deploying to the wrong account.
  allowed_account_ids = ["${local.account_id}"]

  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}

# ── Resilience (L08): transient AWS errors retry instead of failing CI ──
retryable_errors = [
  "(?s).*RequestLimitExceeded.*",
  "(?s).*Throttling.*",
  "(?s).*Failed to lock state.*",
  "(?s).*connection reset.*",
]

# ── Shared inputs (L05): flow into every unit; units add their own ──
inputs = {
  tags = local.common_tags
}
