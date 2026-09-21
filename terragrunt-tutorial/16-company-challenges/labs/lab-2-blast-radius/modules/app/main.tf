# LAB 2 module — trivial file; the lesson is the GUARD in the prod wrapper.

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

resource "local_file" "app" {
  filename = "${path.module}/app-${var.environment}.txt"
  content  = "env=${var.environment}\n"
}

output "file_path" {
  value = local_file.app.filename
}
