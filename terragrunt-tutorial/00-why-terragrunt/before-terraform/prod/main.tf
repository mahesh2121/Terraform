# BEFORE (plain Terraform) — PROD environment.
# ...and the FULL module is duplicated here too. ~95% identical to dev.
# Fix a bug in dev? Remember to fix it here as well. Drift is inevitable.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "message" {
  type    = string
  default = "Hello from PROD"
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-prod.txt"
  content  = var.message
}

output "file_path" {
  value = local_file.greeting.filename
}
