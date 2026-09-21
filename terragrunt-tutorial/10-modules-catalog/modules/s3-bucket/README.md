# Module: s3-bucket

Private S3 bucket with optional versioning and mandatory AES256 encryption.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `bucket_name` | string | (required) | Base bucket name; random suffix appended |
| `versioning_enabled` | bool | `true` | Enable S3 versioning |
| `tags` | map(string) | `{}` | Tags for the bucket |

## Outputs

| Name | Description |
|---|---|
| `bucket_id` | Bucket name/ID |
| `bucket_arn` | Bucket ARN |

## Example wrapper

```hcl
terraform {
  # local dev:
  source = "../../../modules/s3-bucket"
  # production (pinned version):
  # source = "git::https://github.com/acme/infra-modules.git//s3-bucket?ref=v0.5.0"
}

inputs = {
  bucket_name        = "acme-dev-assets"
  versioning_enabled = false
  tags               = { Environment = "dev" }
}
```
