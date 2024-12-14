bucket_name = "mybucket12vpc" // Name of the S3 bucket for storing Terraform state
region = "ap-south-1" // AWS region where resources will be created

project_name = "Couro" // Name of the project

template_var = {
  name          = "Instance Template" // Name of the EC2 instance template
  image_id      = "ami-053b12d3152c0cc71" // AMI ID for the EC2 instance
  instance_type = "t2.micro" // Instance type for the EC2 instance
  key_name      = "secret" // Name of the SSH key pair for accessing the EC2 instance
}

tmp_script_variables = {
  pat_secret_name  = "token" // Name of the secret for the personal access token
  repo_url         = "https://github.com/HusnainIzhar/next-cicd.git" // URL of the GitHub repository
  installation_dir = "/opt/your-app" // Directory where the application will be installed
  app_name         = "next-cicd" // Name of the application
  branch_name      = "main" // Branch name of the GitHub repository
}

ec2_asg_var = {
  desired_capacity          = 2 // Desired number of instances in the Auto Scaling Group
  max_size                  = 3 // Maximum number of instances in the Auto Scaling Group
  min_size                  = 1 // Minimum number of instances in the Auto Scaling Group
  health_check_grace_period = 300 // Health check grace period for the Auto Scaling Group
}