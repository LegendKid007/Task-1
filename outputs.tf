output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "pem_file" {
  description = "Path of the private key PEM file"
  value       = local_file.pem_file.filename
}
