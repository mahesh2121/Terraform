# DEV EC2 unit — THE dependency showcase (L06):
# consumes vpc outputs; run-all orders it after ../vpc automatically.

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id            = "vpc-mock"
    public_subnet_ids = ["subnet-mock1", "subnet-mock2"]
    cidr_block        = "0.0.0.0/0"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

terraform {
  source = "../../../../modules/ec2"
}

inputs = {
  name               = "acme-${local.env.locals.env}"
  environment        = local.env.locals.env
  instance_type      = local.env.locals.instance_type
  monitoring_enabled = local.env.locals.monitoring_enabled

  # Real values flow from the vpc unit's state at apply time:
  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.public_subnet_ids[0]
}
