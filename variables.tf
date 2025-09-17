variable "instance_type" {
  description = "EC2 instance type (default is free-tier eligible)"
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
}
