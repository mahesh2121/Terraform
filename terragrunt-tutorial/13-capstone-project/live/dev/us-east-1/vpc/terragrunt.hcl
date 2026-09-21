# DEV VPC unit — upstream of ec2. No dependencies of its own.

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name                = "acme-${local.env.locals.env}"
  cidr_block          = local.env.locals.vpc_cidr
  public_subnet_cidrs = local.env.locals.public_subnet_cidrs
  azs                 = local.region.locals.azs
}
