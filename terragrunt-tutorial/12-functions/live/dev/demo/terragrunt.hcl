# Lesson 12 — function showcase. Run:
#   terragrunt apply                     (defaults from env.hcl)
#   DEPLOY_COLOR=blue terragrunt apply   (env var override wins)
#   terragrunt destroy

locals {
  # 1) Read the env layer.
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # 2) Env-var override with default (CI-friendly).
  color_override = get_env("DEPLOY_COLOR", "")

  # 3) Path math: derive names from folder location instead of hardcoding.
  unit_dir  = get_terragrunt_dir()         # .../live/dev/demo
  unit_name = basename(local.unit_dir)     # "demo"

  # 4) Merge: base layer first, overrides last (last wins).
  merged = merge(
    local.env_config.locals.common_inputs,
    local.color_override != "" ? { color = local.color_override } : {}
  )
}

terraform {
  source = "../../../modules/demo"
}

inputs = {
  environment = local.env_config.locals.env
  unit_name   = local.unit_name
  color       = local.merged.color
  replicas    = local.merged.replicas
  upper_env   = upper(local.env_config.locals.env) # Terraform OSS fn ✅
}
