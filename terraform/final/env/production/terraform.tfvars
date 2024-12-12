
bucket_name = "your-s3-bucket-name"
region = "us-east-1"

project_name = "your-project-name"

template_var = {
  name          = "example-template"
  image_id      = "ami-xxxxxxxxxxxxxxx"
  instance_type = "t2.micro"
  key_name      = "your-key-pair-name"
}
tmp_script_variables = {
  pat_secret_name  = "your-github-token-secret-name"
  repo_url         = "https://github.com/your/repository"
  installation_dir = "/opt/your-app"
  app_name         = "your-app-name"
}
ec2_asg_var = {
  desired_capacity          = 2
  max_size                 = 5
  min_size                 = 1
  health_check_grace_period = 300
}
