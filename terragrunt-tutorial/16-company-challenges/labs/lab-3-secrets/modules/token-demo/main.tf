# LAB 3 module — demonstrates handling a secret WITHOUT persisting it.
# The file records only WHETHER a token was provided, never the value itself.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "api_token" {
  description = "Demo secret (in production: read from a secrets manager data source)"
  type        = string
  sensitive   = true # plan/apply output shows "(sensitive value)" — redacted ✅
  default     = ""
}

resource "local_file" "status" {
  filename = "${path.module}/token-status-${var.environment}.txt"
  # Boolean only — the secret value NEVER lands in this file. ✅
  content = "token_configured = ${var.api_token != "" ? true : false}\n"
}

output "status_file" {
  value = local_file.status.filename
}
