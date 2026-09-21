# Lesson 05 module — prints WHERE each value came from so you can
# see the root → env → unit layering in the generated file.

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
variable "message" { type = string }
variable "org" {
  type    = string
  default = "unknown-org"
}
variable "managed_by" {
  type    = string
  default = "unknown"
}

resource "local_file" "greeting" {
  filename = "${path.module}/greeting-${var.environment}.txt"
  content  = <<-EOT
    message     = ${var.message}          (came from ENV layer)
    environment = ${var.environment}      (came from ENV layer via unit)
    org         = ${var.org}              (came from ROOT inputs)
    managed_by  = ${var.managed_by}       (came from ROOT inputs)
  EOT
}

output "file_path" {
  value = local_file.greeting.filename
}
