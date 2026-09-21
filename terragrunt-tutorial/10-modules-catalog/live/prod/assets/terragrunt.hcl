# PROD wrapper for the SAME catalog module — only values differ.
# Note how prod could ALSO pin a different (older, proven) module version
# than dev while a new version is being validated. (See Lesson 10 README.)

terraform {
  source = "../../../modules/s3-bucket"
}

inputs = {
  bucket_name        = "acme-prod-assets"
  versioning_enabled = true # prod: always versioned 🛡️
  tags = {
    Environment = "prod"
    ManagedBy   = "terragrunt"
  }
}
