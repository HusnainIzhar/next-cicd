variable "region" {
  description = "The AWS region with availability zones"
  type = object({
    a1 = string
    b1 = string
    c1 = string
  })
  default = {
    a1 = "us-east-1a"
    b1 = "us-east-1b"
    c1 = "us-east-1c"
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
