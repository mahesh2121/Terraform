provider "aws" {
  region = "ap-south-1"
}

module "ec2_instance" {
  source        = "./modules/ec2_module"
  ami           = "ami-04a37924ffe27da53" # Example AMI ID
  instance_type = "t2.micro"
}

# Output the instance ID and public IP
output "instance_id" {
  value = module.ec2_instance.instance_id
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
