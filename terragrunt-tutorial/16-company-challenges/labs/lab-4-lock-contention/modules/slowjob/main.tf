# LAB 4 module — deliberately SLOW (sleep provisioner) so you have time
# to start a second apply and collide with the first one's state lock.

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

variable "sleep_seconds" {
  description = "How long the fake 'deployment' takes (collision window)"
  type        = number
  default     = 25
}

resource "terraform_data" "slow_job" {
  input = var.environment

  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds}"
  }
}

resource "local_file" "receipt" {
  depends_on = [terraform_data.slow_job]
  filename   = "${path.module}/receipt-${var.environment}.txt"
  content    = "job completed for ${var.environment}\n"
}

output "receipt" {
  value = local_file.receipt.filename
}
