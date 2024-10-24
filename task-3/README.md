
# Terraform EC2 Instance Replacement in Case of Degraded Hardware

This repository demonstrates how to use Terraform to deploy an AWS EC2 instance within a module and force the replacement of the instance in case it runs on degraded hardware. This process is useful when AWS notifies you that the physical hardware backing your instance is experiencing performance issues.

## Directory Structure

The project is structured as follows:

```
terraform-project/
│
├── main.tf                 # Root module, calling EC2 instance module
└── modules/
    └── ec2_module/
        ├── main.tf         # Defines the AWS EC2 instance resource
        ├── variables.tf    # Variables for the EC2 instance (AMI, instance type)
        └── outputs.tf      # Outputs for instance ID and public IP
```

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads) installed on your machine.
2. An AWS account with the necessary permissions to create EC2 instances.
3. AWS credentials configured via the AWS CLI or environment variables.

## How to Use

### 1. Clone the Repository

```bash
git clone <repository-url>
cd terraform-project
```

### 2. Initialize the Terraform Project

Initialize the Terraform project to download the required provider plugins.

```bash
terraform init
```

### 3. Apply the Terraform Configuration

To deploy the EC2 instance:

```bash
terraform apply
```

Terraform will create an EC2 instance and output the instance ID and public IP.

### 4. Force a Resource Replacement

If AWS notifies you that the instance is running on degraded hardware, you can force Terraform to replace the instance using the following command:

```bash
terraform plan -replace=module.ec2_instance.aws_instance.example
```

This will plan the replacement of the specific EC2 instance within the `ec2_instance` module.

To apply the replacement:

```bash
terraform apply -replace=module.ec2_instance.aws_instance.example
```

Terraform will destroy the old instance and create a new one on different hardware.

### 5. Clean Up Resources

To clean up and destroy the created resources, run:

```bash
terraform destroy
```

This will terminate the EC2 instance and remove all associated resources.

## Understanding the Code

### Module Code (EC2 Instance)

The EC2 instance is defined in the `modules/ec2_module/main.tf` file:

```hcl
resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type
}

output "instance_id" {
  value = aws_instance.example.id
}
```

Variables for the EC2 instance are passed via `variables.tf`:

```hcl
variable "ami" {
  type        = string
  description = "The AMI ID to use for the EC2 instance."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
}
```

### Root Module

The root module (`main.tf`) calls the EC2 module and passes in the required variables like the AMI ID and instance type:

```hcl
module "ec2_instance" {
  source        = "./modules/ec2_module"
  ami           = "ami-123456"  # Example AMI ID
  instance_type = "t2.micro"
}
```

### Outputs

The root module also outputs the EC2 instance ID and public IP:

```hcl
output "instance_id" {
  value = module.ec2_instance.instance_id
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
```

## When to Force a Resource Replacement

You may need to force the replacement of an EC2 instance in the following situations:

- AWS notifies you that the instance is running on degraded hardware.
- The instance is experiencing performance issues due to underlying physical hardware failure.
- Network or disk I/O issues that are related to the instance's hardware.

Using the `-replace` option in Terraform allows you to explicitly replace specific resources, ensuring the instance moves to healthier hardware.

## Conclusion

This project demonstrates how to manage EC2 instances in Terraform and handle degraded hardware scenarios by forcing the replacement of the instance. This technique ensures your applications run smoothly on healthy hardware.
