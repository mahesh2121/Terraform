# EC2 Instance Resource
resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type
}

# Output the instance ID
output "instance_id" {
  value = aws_instance.example.id
}
