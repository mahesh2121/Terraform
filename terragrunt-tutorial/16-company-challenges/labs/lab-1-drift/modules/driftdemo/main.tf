# LAB 1 module — a file whose CONTENT is fully managed by Terraform,
// so any hand-edit is drift that `plan` will flag.

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

variable "message" {
  type    = string
  default = "managed by terraform"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

resource "local_file" "notice" {
  filename = "${path.module}/notice-${var.environment}.txt"
  content  = <<-EOT
    message = ${var.message}
    owner   = ${var.owner}
  EOT
}

output "file_path" {
  value = local_file.notice.filename
}
