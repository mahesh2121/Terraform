# BEFORE (plain Terraform) — DEV variables file.
# Another file that exists per environment.

variable "environment" {
  type    = string
  default = "dev"
}
