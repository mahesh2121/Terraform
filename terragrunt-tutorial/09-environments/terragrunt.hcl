# ROOT — Lesson 09. Shared org inputs for every env/region/unit.
# (Real roots also carry remote_state + provider generate + retries.)

# Parent-only config: defines shared settings but no unit of its own,
# so run-all skips executing it (children still inherit via include).
skip = true

locals {
  org = "acme"
}

inputs = {
  org = local.org
}
