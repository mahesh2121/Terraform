# PROD environment values — same KEYS as dev, production VALUES.
# Promotion = copy a change here after it proves itself in dev. (L09)

locals {
  env        = "prod"
  account_id = "111111111111" # ← REPLACE (ideally a SEPARATE prod account!)

  # Network (non-overlapping with dev, room to grow)
  vpc_cidr           = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]

  # Compute (bigger + monitored)
  instance_type      = "t3.small"
  monitoring_enabled = true

  # Storage (always versioned in prod 🛡️)
  versioning_enabled = true
}
