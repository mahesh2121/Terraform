# modules/ec2_module/outputs.tf

output "instance_id" {
  value = aws_instance.example.*.id  # Outputs all instance IDs
}

output "instance_public_ip" {
  value = aws_instance.example.*.public_ip  # Outputs all public IPs
}
