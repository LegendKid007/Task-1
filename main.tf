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

# Generate Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save PEM locally
resource "local_file" "pem_file" {
  filename        = "${path.module}/${var.key_name}.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0400"
}

# EC2 Instance with Java preinstalled
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              exec > /home/ec2-user/setup.log 2>&1
              set -xe

              echo ">>> Updating packages..."
              yum update -y

              echo ">>> Enabling Amazon Corretto 17..."
              amazon-linux-extras enable corretto17

              echo ">>> Installing Java 17..."
              yum install -y java-17-amazon-corretto

              echo ">>> Waiting for Java to be available..."
              for i in {1..30}; do
                if command -v java >/dev/null 2>&1; then
                  echo "✅ Java installed"
                  java -version
                  break
                fi
                echo "⏳ Java not ready yet, retrying..."
                sleep 10
              done

              echo ">>> Setup complete."
              EOT

  tags = {
    Name = var.key_name
  }
}
