# BEFORE (plain Terraform) — PROD variables file.
# Yet another near-duplicate of dev.

variable "environment" {
  type    = string
  default = "prod"
}
