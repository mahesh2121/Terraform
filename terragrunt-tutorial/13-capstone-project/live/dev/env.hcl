# DEV environment values.
# ⚠️ Set account_id to YOUR AWS account (aws sts get-caller-identity).

locals {
  env        = "dev"
  account_id = "111111111111" # ← REPLACE with your account id

  # Network
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

  # Compute (small + cheap for dev)
  instance_type      = "t3.micro"
  monitoring_enabled = false

  # Storage (unversioned in dev to save cost)
  versioning_enabled = false
}
