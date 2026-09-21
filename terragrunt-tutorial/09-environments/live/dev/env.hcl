# DEV-wide values. prod/env.hcl has the same KEYS, different VALUES —
# that symmetry is what makes promotion a copy-paste of values, not logic.

locals {
  env               = "dev"
  instance_type     = "t3.micro"
  replicas          = 1
  enable_monitoring = false
}
