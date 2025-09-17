variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}

variable "instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t3.micro"
}
