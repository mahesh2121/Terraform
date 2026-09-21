# AFTER (fixed) — THE one-word fix on line 6: .name → .region
# `terraform validate` → Success! The configuration is valid.
# (No warnings — same line number as before/ for easy diffing.)

locals {
  region     = data.aws_region.current.region
  account_id = "111111111111" # placeholder — validates without any AWS call
}
