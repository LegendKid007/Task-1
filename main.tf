provider "aws" {
  region = "us-east-1"
}

# ✅ Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ✅ Get default VPC
data "aws_vpc" "default" {
  default = true
}

# ✅ Security Group
resource "aws_security_group" "app_sg" {
  name   = "app_sg"
  vpc_id = data.aws_vpc.default.id

  # Allow SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow app on port 9091
  ingress {
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ Generate SSH Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ✅ Save PEM file locally
resource "local_file" "pem_file" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "./${var.key_name}.pem"
  file_permission      = "0400"
  directory_permission = "0777"
}

# ✅ Upload public key to AWS
resource "aws_key_pair" "generated" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# ✅ Create EC2 Instance
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
