# ROOT config — Lesson 05.
# Holds everything shared by ALL units: org-wide locals + common inputs.
# (A real root would also hold `remote_state` (L03) and provider `generate` (L07).)

# Parent-only config: defines shared settings but no unit of its own,
# so run-all skips executing it (children still inherit via include).
skip = true

locals {
  org         = "acme"
  managed_by  = "terragrunt"
  default_tags = {
    Org       = "acme"
    ManagedBy = "terragrunt"
  }
}

# These inputs flow into EVERY unit automatically (children can override).
inputs = {
  org        = local.org
  managed_by = local.managed_by
}
