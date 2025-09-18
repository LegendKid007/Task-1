provider "aws" {
  region = "us-east-1"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow SSH and app port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Latest Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable corretto17
              yum install -y java-17-amazon-corretto
              echo "✅ Java installed" >> /home/ec2-user/setup.log
              java -version >> /home/ec2-user/setup.log 2>&1
              EOT

  tags = {
    Name = var.key_name
  }
}
