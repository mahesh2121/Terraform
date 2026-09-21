# BEFORE (plain Terraform) — DEV environment.
# The FULL module is duplicated here...

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
  default = "Hello from DEV"
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-dev.txt"
  content  = var.message
}

output "file_path" {
  value = local_file.greeting.filename
}
