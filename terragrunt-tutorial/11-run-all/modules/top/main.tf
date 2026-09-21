# CHAIN LINK 3/3 — consumes middle_id. Last in apply order.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "environment" { type = string }
variable "middle_id" { type = string }

resource "local_file" "top" {
  filename = "${path.module}/top-${var.environment}.txt"
  content  = "top unit, built on ${var.middle_id}\n"
}

output "top_id" {
  value = "top-${var.environment}-id"
}
