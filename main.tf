terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "pem_file" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

resource "aws_security_group" "app_sg" {
  name   = "app_sg"
  vpc_id = data.aws_vpc.default.id

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

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  subnet_id                   = element(data.aws_subnet_ids.default.ids, 0)

  user_data = <<-EOT
              #!/bin/bash
              exec > /home/ec2-user/setup.log 2>&1
              set -xe

              echo ">>> Updating system..."
              yum update -y

              echo ">>> Adding Corretto repo..."
              rpm --import https://yum.corretto.aws/corretto.key
              curl -L https://yum.corretto.aws/corretto.repo -o /etc/yum.repos.d/corretto.repo

              echo ">>> Installing Java 17..."
              yum install -y java-17-amazon-corretto

              echo ">>> Verifying Java..."
              java -version || exit 1

              echo ">>> Setup complete."
              EOT

  tags = {
    Name = var.key_name
  }
}

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "pem_file" {
  value = local_file.pem_file.filename
}
