# UPSTREAM module — pretends to be a VPC: it "creates" a network id
# and exposes it as an output for downstream units to consume.

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
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

resource "local_file" "network" {
  filename = "${path.module}/network-${var.environment}.txt"
  content  = "cidr=${var.cidr_block}\n"
}

# ⬇️ DOWNSTREAM units read THIS via dependency.network.outputs.network_id
output "network_id" {
  description = "Fake network id (like a vpc_id)"
  value       = "net-${var.environment}-12345"
}

output "cidr_block" {
  description = "The CIDR of this network"
  value       = var.cidr_block
}
