variable "sg_alb" {
  description = "The ID of the security group"
  type        = string
}

variable "public_subnet_us_east_1a" {
  description = "The ID of the public subnet in us-east-1a"
  type        = string
}

variable "public_subnet_us_east_1b" {
  description = "The ID of the public subnet in us-east-1b"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "aws_autoscaling_group_id" {
  description = "The ID of the Auto Scaling group"

}
