# Initialize Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
  backend "s3" {
    bucket = var.bucket_name
    key    = "backend.tfstate"
    region = var.region
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.region
}

# Create a VPC
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "subnets" {
  source       = "./modules/subnets"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
}

module "security_groups" {
  source       = "./modules/security_groups"
  vpc_id       = module.vpc.vpc_id
}

module "ec2" {
  source       = "./modules/ec2"
  template_var = var.template_var
  project_name = var.project_name
  ec2_security_group_id = module.security_groups.ec2_security_group_id
  subnet_id = module.subnets.private_subnet_us_east_1a_id
  tmp_script_variables = var.tmp_script_variables
}

module "asg" {
  source                     = "./modules/asg"
  ec2_asg_var = var.ec2_asg_var
  ec2_template_launch_id = module.ec2.ec2_template_launch_id
  subnet_id = module.subnets.private_subnet_us_east_1a_id
}

module "alb" {
  source                        = "./modules/alb"
  sg_id = module.security_groups.alb_security_group_id
  public_subnet_us_east_1a = module.subnets.public_subnet_us_east_1a_id
  public_subnet_us_east_1b = module.subnets.public_subnet_us_east_1b_id
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  aws_autoscaling_group_id = module.asg.aws_autoscaling_group_id
}
