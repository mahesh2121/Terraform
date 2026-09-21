# Pure Terraform module — reusable, environment-agnostic.
# NOTE: intentionally NO backend block and NO hardcoded values.
# The wrapper (terragrunt.hcl) supplies `message` and `environment`.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-${var.environment}.txt"
  content  = "${var.message}\n"
}

output "file_path" {
  description = "Absolute path of the file that was created"
  value       = local_file.greeting.filename
}

output "message" {
  description = "The message written into the file"
  value       = var.message
}
