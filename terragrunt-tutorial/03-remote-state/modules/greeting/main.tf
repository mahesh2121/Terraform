# Same reusable module as Lesson 02 (unchanged on purpose!):
# the module doesn't know or care where state lives. The wrapper decides.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "message" {
  description = "Message to write into the greeting file"
  type        = string
}

variable "environment" {
  description = "Environment name, used to name the file (dev/stage/prod...)"
  type        = string
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-${var.environment}.txt"
  content  = "${var.message}\n"
}

output "file_path" {
  description = "Absolute path of the file that was created"
  value       = local_file.greeting.filename
}
