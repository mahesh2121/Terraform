# ENV layer for the functions lesson — provides the base layer that the
# unit merges with (and can override via get_env, see the unit file).

locals {
  env = "dev"

  common_inputs = {
    color    = "green"
    replicas = 1
  }
}
