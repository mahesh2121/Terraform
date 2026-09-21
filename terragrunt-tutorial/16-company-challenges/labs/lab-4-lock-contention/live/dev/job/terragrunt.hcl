# LAB 4 wrapper.
# STEP 1-3: use as-is (default lock timeout = fail fast on contention).
# STEP 4: uncomment the block below → contended applies WAIT instead of failing.

# extra_arguments "lock_timeout" {
#   commands  = ["apply", "plan", "destroy"]
#   arguments = ["-lock-timeout=60s"]
# }

terraform {
  source = "../../../modules/slowjob"
}

inputs = {
  environment   = "dev"
  sleep_seconds = 25
}
