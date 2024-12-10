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

# Private subnet 1
resource "aws_subnet" "private-subnet-ap-south-1a" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  vpc_id     = aws_vpc.myvpc.id 
  tags = {
    Name = "private-subnet-ap-south-1a"
  }
}

# Private subnet 2
resource "aws_subnet" "private-subnet-ap-south-1b" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  vpc_id     = aws_vpc.myvpc.id
  tags = {
    Name = "private-subnet-ap-south-1b"
  }
}

# Public subnet 1
resource "aws_subnet" "public-subnet-ap-south-1a" {
  cidr_block              = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  vpc_id                  = aws_vpc.myvpc.id 
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet ap-south-1a"
  }
}

# Public subnet 2
resource "aws_subnet" "public-subnet-ap-south-1b" {
  cidr_block              = "10.0.3.0/24"
  availability_zone = "ap-south-1b"
  vpc_id                  = aws_vpc.myvpc.id 
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet ap-south-1b"
  }
}

# Internet gateway
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.myvpc.id 
  tags = {
    Name = "my-igw"
  }
}

# Routing table
resource "aws_route_table" "my-rt" {
  vpc_id = aws_vpc.myvpc.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}

# Routing Association with Public Subnet-1
resource "aws_route_table_association" "public-sub" {
  route_table_id = aws_route_table.my-rt.id
  subnet_id      = aws_subnet.public-subnet-ap-south-1a.id
  
}

# Routing Association with Public Subnet-2
resource "aws_route_table_association" "public-sub" {
  route_table_id = aws_route_table.my-rt.id
  subnet_id      = aws_subnet.public-subnet-ap-south-1b.id
  
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

# Output Elastic IP .
output "ec2_public_ip" {
  value = aws_eip.my_eip.public_ip
}
