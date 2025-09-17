provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow SSH and app port"

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

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "key_name" {}
variable "instance_type" {}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = var.key_name
  }

  user_data = <<-EOT
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras enable corretto17
              sudo yum install -y java-17-amazon-corretto -y
              java -version
              EOT
}

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}
