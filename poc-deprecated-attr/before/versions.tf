# BEFORE (broken) — pins AWS provider v6, where the old .name attribute
# of the aws_region data source is deprecated. `terraform validate` here
# REPRODUCES the warning.

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
