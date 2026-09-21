# DEV app unit — reads env + region layers, passes them as inputs.
# Compare with the prod twin: IDENTICAL except folder location.
# All differences come from env.hcl/region.hcl. That's the design. 🎯

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
  # from env.hcl
  environment        = local.env.locals.env
  instance_type      = local.env.locals.instance_type
  replicas           = local.env.locals.replicas
  enable_monitoring  = local.env.locals.enable_monitoring
  # from region.hcl
  aws_region         = local.region.locals.aws_region
  # from root inputs: org (inherited automatically)
}
