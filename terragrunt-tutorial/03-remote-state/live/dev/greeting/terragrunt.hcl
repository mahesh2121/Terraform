# Lesson 03 — same tiny wrapper as Lesson 02, plus ONE include line.
# The S3 backend (bucket/key/region/locks) is inherited from the root config.
# Nothing about state is repeated here. That's the whole point. 🎉

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/greeting"
}

inputs = {
  environment = "dev"
  message     = "Hello with remote state!"
}
