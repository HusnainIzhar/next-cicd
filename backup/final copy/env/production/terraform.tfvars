
bucket_name = "mybucket12vpc"
region = "ap-south-1"

project_name = "Couro"

template_var = {
  name          = "Instance Template"
  image_id      = "ami-053b12d3152c0cc71"
  instance_type = "t2.micro"
  key_name      = "secret"
}
tmp_script_variables = {
  pat_secret_name  = "token"
  repo_url         = "https://github.com/HusnainIzhar/next-cicd.git"
  installation_dir = "/opt/your-app"
  app_name         = "next-cicd"
  branch_name = "main"
}
ec2_asg_var = {
  desired_capacity          = 2
  max_size                 = 3
  min_size                 = 1
  health_check_grace_period = 300
}
