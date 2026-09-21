# DEV S3 assets bucket — independent unit (no dependencies),
# so run-all deploys it in PARALLEL with vpc. (L11)

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
