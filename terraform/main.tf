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

data "aws_route53_zone" "selected" {
  name = var.domain_name
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "subnets" {
  source       = "./modules/subnets"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  vpc_cidr_block = module.vpc.vpc_cidr_block
}

module "acm" {
  source = "./modules/acm"
  domain_name = var.domain_name
  zone_id = data.aws_route53_zone.selected.zone_id
  
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
  tmp_script_variables = var.tmp_script_variables
}

module "asg" {
  source                     = "./modules/asg"
  ec2_asg_var = var.ec2_asg_var
  ec2_template_launch_id = module.ec2.ec2_template_launch_id
  private_subnet = module.subnets.private_subnet
  aws_lb_target_group = module.alb.aws_alb_target_group_id
  project_name = var.project_name
  launch_template_latest_version = module.ec2.launch_template_latest_version
}

module "alb" {
  source                        = "./modules/alb"
  sg_alb = module.security_groups.sg_alb
  public_subnet = module.subnets.public_subnet
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  aws_internet_gateway = module.subnets.aws_internet_gateway
  aws_acm_certificate = module.acm.aws_acm_certificate
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = module.asg.asg_auto_scaling_group_id
  lb_target_group_arn    = module.alb.aws_alb_target_group_id
}