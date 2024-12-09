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

# Region
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myvpc"
  }
}

# Private subnet
resource "aws_subnet" "private-subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.myvpc.id  # Corrected reference
  tags = {
    Name = "private-subnet"
  }
}

# Public subnet
resource "aws_subnet" "public-subnet" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.myvpc.id  # Corrected reference
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Internet gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.myvpc.id  # Corrected reference
  tags = {
    Name = "my-igw"
  }
}

# Routing table
resource "aws_route_table" "my-rt" {
  vpc_id = aws_vpc.myvpc.id  # Corrected reference

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

# Routing Association with Public Subnet
resource "aws_route_table_association" "public-sub" {
  route_table_id = aws_route_table.my-rt.id
  subnet_id      = aws_subnet.public-subnet.id
}

# Define the EC2 instance
resource "aws_instance" "MyServer" {
  ami                         = "ami-053b12d3152c0cc71"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-subnet.id
  key_name                    = "secret"
  associate_public_ip_address = true

  tags = {
    Name = "app"
  }
}

# Create Elastic IP
resource "aws_eip" "my_eip" {
  instance = aws_instance.MyServer.id
}


# Output EC2 Instance Public DNS
output "ec2_public_dns" {
  value = aws_instance.MyServer.public_dns
}
