terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }

  backend "s3" {
    bucket = "mybucketprod"
    key    = "backend.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}


# Define the EC2 instance5
resource "aws_instance" "MyServer" {
  ami           = "ami-053b12d3152c0cc71"
  instance_type = "t2.micro"
  key_name      = "secret"

  tags = {
    Name = "app"
  }
}
output "ec2_public_dns" {
  value = aws_instance.MyServer.public_dns
}
