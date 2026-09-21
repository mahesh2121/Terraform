variable "name" {
  description = "Name prefix for resources (e.g. acme-dev)"
  type        = string
}

variable "environment" {
  description = "Environment name (shown on the demo web page)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC to launch into (from dependency outputs)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch into (from dependency outputs)"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDRs allowed to SSH (restrict to your IP in real usage!)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Existing EC2 key pair name (empty = no SSH key)"
  type        = string
  default     = ""
}

variable "monitoring_enabled" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
