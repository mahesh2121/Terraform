# modules/ec2_module/variables.tf

variable "ami" {
  type        = string
  description = "The AMI ID to use for the EC2 instance."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
}
