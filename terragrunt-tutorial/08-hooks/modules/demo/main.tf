# Lesson 08 module — same trivial local_file module; the interesting
# parts are the HOOKS in the wrapper, not the resources.

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

resource "local_file" "demo" {
  filename = "${path.module}/demo-${var.environment}.txt"
  content  = "hooks lesson\n"
}

output "file_path" {
  value = local_file.demo.filename
}
