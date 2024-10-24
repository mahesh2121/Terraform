# modules/ec2_module/main.tf

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = "Instance"  # Tagging instances based on count index
  }
}

