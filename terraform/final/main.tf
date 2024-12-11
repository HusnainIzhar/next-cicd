# Initialize Terraform
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

# AWS Provider Configuration
provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source = "./modules/vpc"
}

module "subnets" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  private_subnet_id = module.subnets.private_subnet_id
  security_group_id = module.security_groups.ec2_sg_id
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.subnets.public_subnet_ids
  security_group_id = module.security_groups.lb_sg_id
  target_group_arn = module.ec2.target_group_arn
}

output "load_balancer_dns" {
  value = module.alb.load_balancer_dns
}