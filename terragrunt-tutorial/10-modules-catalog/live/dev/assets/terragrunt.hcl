# DEV wrapper for the s3-bucket catalog module.
# Only VALUES live here — no resource logic. Needs AWS credentials to apply.
#   terragrunt plan && terragrunt apply && terragrunt destroy

terraform {
  # Learning: local path. Production: pinned git URL, e.g.
  # source = "git::https://github.com/acme/infra-modules.git//s3-bucket?ref=v0.5.0"
  source = "../../../modules/s3-bucket"
}

inputs = {
  bucket_name        = "acme-dev-assets"
  versioning_enabled = false # dev: save cost; prod enables it (see twin file)
  tags = {
    Environment = "dev"
    ManagedBy   = "terragrunt"
  }
}
