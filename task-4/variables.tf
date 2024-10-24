# variables.tf

variable "env" {
  type        = string
  description = "Environment name (dev, stag, prod)"
  default     = "dev" # Default environment
}

variable "ami" {
  type        = string
  description = "The AMI ID to use for the EC2 instance."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
}
