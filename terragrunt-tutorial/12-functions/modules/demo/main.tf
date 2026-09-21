# Lesson 12 module — echoes every function result into a file so you can
# verify each one after apply.

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
variable "unit_name" { type = string }
variable "color" { type = string }
variable "replicas" { type = number }
variable "upper_env" { type = string }

resource "local_file" "demo" {
  filename = "${path.module}/demo-${var.environment}.txt"
  content  = <<-EOT
    environment = ${var.environment}   (read_terragrunt_config → env.hcl)
    unit_name   = ${var.unit_name}      (basename(get_terragrunt_dir()))
    color       = ${var.color}          (merge of env.hcl + DEPLOY_COLOR override)
    replicas    = ${var.replicas}       (merge base layer)
    upper_env   = ${var.upper_env}      (Terraform upper() function)
  EOT
}

output "file_path" {
  value = local_file.demo.filename
}
