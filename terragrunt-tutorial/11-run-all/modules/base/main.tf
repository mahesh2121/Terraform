# CHAIN LINK 1/3 — no inputs from other units; produces base_id.

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

resource "local_file" "base" {
  filename = "${path.module}/base-${var.environment}.txt"
  content  = "base unit\n"
}

output "base_id" {
  value = "base-${var.environment}-id"
}
