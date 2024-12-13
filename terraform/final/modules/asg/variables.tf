variable "ec2_asg_var" {
  description = "A variable to demonstrate the use of templates"
  type = object({
    desired_capacity          = number
    max_size                 = number
    min_size                 = number
    health_check_grace_period = number
  })
}

variable "ec2_template_launch_id" {
  description = "The ID of the launch template"
  type        = string
}

variable "private_subnet_us_east_1a" {
  description = "The ID of the subnet"
  type        = string
}

variable "private_subnet_us_east_1b" {
  description = "The ID of the subnet"
  type        = string
  
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  
}

