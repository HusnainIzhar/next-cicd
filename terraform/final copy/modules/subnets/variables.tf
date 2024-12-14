variable "availability_zone" {
  type = list(string)
  description = "Availability Zones"
  default = [ "ap-south-1a","ap-south-1b" ]
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
  
}
