# Lesson 09 module — one module serves ALL envs × regions.
# Every environment-specific thing is a variable. No defaults that assume env.

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
variable "instance_type" { type = string }
variable "replicas" { type = number }
variable "enable_monitoring" { type = bool }
variable "aws_region" { type = string }
variable "org" {
  type    = string
  default = "unknown"
}

resource "local_file" "app" {
  filename = "${path.module}/app-${var.environment}.txt"
  content  = <<-EOT
    org               = ${var.org}
    environment       = ${var.environment}
    aws_region        = ${var.aws_region}
    instance_type     = ${var.instance_type}
    replicas          = ${var.replicas}
    enable_monitoring = ${var.enable_monitoring}
  EOT
}

output "file_path" {
  value = local_file.app.filename
}
