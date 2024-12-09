terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }

  backend "s3" {
    bucket = "mybucket-87654321"
    key    = "backend.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Define the security group
resource "aws_security_group" "MyServerSG" {
  name        = "MyServerSecurityGroup"
  description = "Allow SSH access"

  # Ingress rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP for better security
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyServerSecurityGroup"
  }
}

# Define the EC2 instance
resource "aws_instance" "MyServer" {
  ami           = "ami-053b12d3152c0cc71"
  instance_type = "t2.micro"
  key_name      = "secret"

  # Associate the security group with the instance
  vpc_security_group_ids = [aws_security_group.MyServerSG.id]

  tags = {
    Name = "server1"
  }
}

output "ec2_public_dns" {
  value = aws_instance.MyServer.public_dns
}
