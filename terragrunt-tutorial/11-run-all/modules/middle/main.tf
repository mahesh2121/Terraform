# CHAIN LINK 2/3 — consumes base_id, produces middle_id.

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
variable "base_id" { type = string }

resource "local_file" "middle" {
  filename = "${path.module}/middle-${var.environment}.txt"
  content  = "middle unit, built on ${var.base_id}\n"
}

output "middle_id" {
  value = "middle-${var.environment}-id"
}
