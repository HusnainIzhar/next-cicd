terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
  backend "s3" {
    bucket = "mybucket12vpc"
    key    = "backend.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.region
}

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
  source       = "./modules/sg"
  vpc_id       = module.vpc.vpc_id
}

module "ec2" {
  source       = "./modules/ec2"
  template_var = var.template_var
  project_name = var.project_name
  sg_ec2  = module.security_groups.sg_ec2
  subnet_private_us_east_1a = module.subnets.private_subnet_us_east_1a_id
  tmp_script_variables = var.tmp_script_variables
}

module "asg" {
  source                     = "./modules/asg"
  ec2_asg_var = var.ec2_asg_var
  ec2_template_launch_id = module.ec2.ec2_template_launch_id
  private_subnet_us_east_1a = module.subnets.private_subnet_us_east_1a_id
  private_subnet_us_east_1b = module.subnets.private_subnet_us_east_1b_id
  project_name = var.project_name
  aws_alb_target_group_id = module.alb.aws_alb_target_group_id
}

module "alb" {
  source                        = "./modules/alb"
  sg_alb = module.security_groups.sg_alb
  public_subnet_us_east_1a = module.subnets.public_subnet_us_east_1a_id
  public_subnet_us_east_1b = module.subnets.public_subnet_us_east_1b_id
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  aws_autoscaling_group_id = module.asg.asg_auto_scaling_group_id
}