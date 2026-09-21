# PROD S3 assets bucket — versioning ON via prod env.hcl. (L09/L10)

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/s3-bucket"
}

inputs = {
  bucket_name        = "acme-${local.env.locals.env}-assets"
  versioning_enabled = local.env.locals.versioning_enabled
}
