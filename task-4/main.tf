# main.tf

provider "aws" {
  region = "ap-south-1" # Change to your preferred region
}

module "ec2_instance" {
  source        = "./modules/ec2_module"
  ami           = var.ami # Replace with your AMI ID
  instance_type = var.instance_type

  # Create 1 instance in dev, 2 in stag, and 3 in prod
  count = var.env == "dev" ? 1 : var.env == "stag" ? 2 : var.env == "prod" ? 3 : 0
}
