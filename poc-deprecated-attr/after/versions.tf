# AFTER (fixed) — same v6 pin. Only locals.tf changed (.name → .region),
# and `terraform validate` is now completely clean.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
