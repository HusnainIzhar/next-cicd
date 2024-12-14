# Variable for S3 Bucket Name
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default = "ap-south-1"
}

# Variable for AWS Region
variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

# Variable for Project Name
variable "project_name" {
  description = "The name of the project"
  type        = string
}

# Variable for Template Configuration
variable "template_var" {
  description = "A variable to demonstrate the use of templates"
  type = object({
    name          = string
    image_id      = string
    instance_type = string
    key_name      = string
  })
}

variable "tmp_script_variables" {
  description = "An object containing variables for the user-data script"
  type = object({
    pat_secret_name   = string  # Name of the secret in AWS Secrets Manager for GitHub token
    repo_url          = string  # GitHub repository URL
    installation_dir  = string  # Directory where the app will be installed
    app_name          = string
    branch_name = string  # Name of the app being deployed
  })
}

variable "ec2_asg_var" {
  description = "A variable to demonstrate the use of templates"
  type = object({
    desired_capacity          = number
    max_size                 = number
    min_size                 = number
    health_check_grace_period = number
  })
}

variable "domain_name" {
  type = string
  default = "emarkrealty.com"
  
}