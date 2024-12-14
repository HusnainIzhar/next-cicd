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

variable "private_subnet" {
  description = "The ID of the private subnet in us-east-1a"
  type        = list(string)
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  
}

variable "aws_lb_target_group" {
  description = "value of the target group"
  type        = string
}

