variable "message" {
  description = "Message to write into the greeting file"
  type        = string
}

variable "environment" {
  description = "Environment name, used to name the file (dev/stage/prod...)"
  type        = string
}
