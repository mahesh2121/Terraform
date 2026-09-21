# PROD-wide values — same keys as dev/env.hcl, production-sized values.

locals {
  env               = "prod"
  instance_type     = "t3.medium"
  replicas          = 3
  enable_monitoring = true
}
