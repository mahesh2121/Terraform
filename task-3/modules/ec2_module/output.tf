# Outputs the instance public IP
output "public_ip" {
  value = aws_instance.example.public_ip
}
