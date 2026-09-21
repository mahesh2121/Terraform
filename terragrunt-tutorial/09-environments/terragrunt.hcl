# ROOT — Lesson 09. Shared org inputs for every env/region/unit.
# (Real roots also carry remote_state + provider generate + retries.)

locals {
  org = "acme"
}

inputs = {
  org = local.org
}
