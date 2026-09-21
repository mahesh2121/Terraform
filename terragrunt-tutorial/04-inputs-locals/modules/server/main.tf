# Lesson 04 module: accepts several variable TYPES so you can see how
# `inputs` maps onto each one (string, number, bool, map, list).

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

variable "server_name" {
  description = "Name of the (pretend) server"
  type        = string
}

variable "instance_type" {
  description = "Instance type label (just written into the file)"
  type        = string
}

variable "replicas" {
  description = "How many replicas (number example)"
  type        = number
  default     = 1
}

variable "monitoring_enabled" {
  description = "Whether monitoring is on (bool example)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags map (map example)"
  type        = map(string)
  default     = {}
}

resource "local_file" "server" {
  filename = "${path.module}/${var.server_name}.txt"
  content  = <<-EOT
    server_name        = ${var.server_name}
    instance_type      = ${var.instance_type}
    replicas           = ${var.replicas}
    monitoring_enabled = ${var.monitoring_enabled}
    tags               = ${jsonencode(var.tags)}
  EOT
}

output "file_path" {
  value = local_file.server.filename
}
