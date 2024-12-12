variable "region" {
  description = "The AWS region with availability zones"
  type = object({
    a1 = string
    b1 = string
    c1 = string
  })
  default = {
    a1 = "ap-south-1a"
    b1 = "ap-south-1b"
    c1 = "ap-south-1c"
  }
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
