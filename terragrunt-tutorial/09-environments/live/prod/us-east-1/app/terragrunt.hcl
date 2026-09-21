# PROD app unit — byte-identical structure to the dev twin.
# find_in_parent_folders resolves to PROD's env.hcl/region.hcl automatically
# because resolution is based on THIS file's location. No edits needed. 🎯

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
  source = "../../../../modules/app"
}

inputs = {
  # from env.hcl (prod values!)
  environment        = local.env.locals.env
  instance_type      = local.env.locals.instance_type
  replicas           = local.env.locals.replicas
  enable_monitoring  = local.env.locals.enable_monitoring
  # from region.hcl
  aws_region         = local.region.locals.aws_region
  # from root inputs: org (inherited automatically)
}
