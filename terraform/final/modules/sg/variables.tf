variable "vpc_id" {
  description = "The ID of the VPC endpoint"
  type        = string
  
}

variable "sg_alb" {
  description = "Security group for alb"
  type = string
  
}