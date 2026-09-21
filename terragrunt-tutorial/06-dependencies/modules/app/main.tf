# DOWNSTREAM module — pretends to be an app that must be told
# which network to join. It CANNOT guess; the wrapper injects network_id.

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
variable "network_id" {
  description = "ID of the network to join (comes from dependency outputs)"
  type        = string
}

resource "local_file" "app" {
  filename = "${path.module}/app-${var.environment}.txt"
  content  = "joined network: ${var.network_id}\n"
}

output "file_path" {
  value = local_file.app.filename
}
