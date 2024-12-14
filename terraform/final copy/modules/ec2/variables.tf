variable "template_var" {
  description = "An object containing the parameters for the EC2 launch template"
  type = object({
    name           = string
    image_id       = string
    instance_type  = string
    key_name       = string
  })
}

variable "project_name" {
  description = "The name of the project for tagging and resource identification"
  type        = string
}

variable "sg_ec2" {
  description = "The ID of the security group to be attached to the EC2 instance"
  type        = string
}


variable "tmp_script_variables" {
  description = "An object containing variables for the user-data script"
  type = object({
    pat_secret_name   = string  # Name of the secret in AWS Secrets Manager for GitHub token
    repo_url          = string  # GitHub repository URL
    installation_dir  = string  # Directory where the app will be installed
    app_name          = string  # Name of the app being deployed
  })
}
