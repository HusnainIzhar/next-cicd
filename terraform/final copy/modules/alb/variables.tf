variable "sg_alb" {
  description = "The ID of the security group"
  type        = string
}

variable "public_subnet" {
  description = "The ID of the public subnet in us-east-1a"
  type        = list(string)
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "aws_internet_gateway" {
  description = "The ID of the internet gateway"
  
}
