# AFTER (Terragrunt) — the Terraform module, written ONCE.
# Pure Terraform here: no backend block, no environment specifics.
# Terragrunt supplies `message` via `inputs` (see live/*/terragrunt.hcl).

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "message" {
  description = "Message to write into the file"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod/...)"
  type        = string
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-${var.environment}.txt"
  content  = var.message
}

output "file_path" {
  value = local_file.greeting.filename
}
