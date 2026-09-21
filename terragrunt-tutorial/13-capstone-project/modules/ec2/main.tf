# MODULE: ec2 — one instance + security group in a GIVEN subnet/vpc.
# Notice: it takes vpc_id/subnet_id as VARIABLES — the wrapper injects them
# from `dependency.vpc.outputs` (L06). The module knows nothing about Terragrunt.

# Always use the latest Amazon Linux 2 AMI — no hardcoded, stale AMI IDs.
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Allow SSH and HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  key_name               = var.key_name != "" ? var.key_name : null
  monitoring             = var.monitoring_enabled

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Hello from ${var.name} (${var.environment})</h1>" > /var/www/html/index.html
  EOF

  tags = merge(var.tags, { Name = "${var.name}-web" })
}
